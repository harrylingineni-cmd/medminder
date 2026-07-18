import 'dart:convert';

import 'package:http/http.dart' as http;

/// What happened when a US medicine name was looked up through RxNav.
enum RxNavLookupOutcome { found, notFound, networkError }

/// The result shown by the US Find Generic flow.
///
/// Approximate RxNorm matches are candidates for manual review, not answers.
/// The UI must show [matchedMedicineName] and receive explicit confirmation
/// before it reveals [genericName].
class RxNavLookupResult {
  final RxNavLookupOutcome outcome;
  final String? genericName;
  final String? matchedMedicineName;
  final bool requiresMatchConfirmation;

  const RxNavLookupResult._({
    required this.outcome,
    this.genericName,
    this.matchedMedicineName,
    this.requiresMatchConfirmation = false,
  });

  const RxNavLookupResult.found({
    required String genericName,
    required String matchedMedicineName,
    bool requiresMatchConfirmation = false,
  }) : this._(
         outcome: RxNavLookupOutcome.found,
         genericName: genericName,
         matchedMedicineName: matchedMedicineName,
         requiresMatchConfirmation: requiresMatchConfirmation,
       );

  const RxNavLookupResult.notFound()
    : this._(outcome: RxNavLookupOutcome.notFound);

  const RxNavLookupResult.networkError()
    : this._(outcome: RxNavLookupOutcome.networkError);
}

class _RxNavMatch {
  final String rxcui;
  final String displayName;
  final bool isApproximate;

  const _RxNavMatch({
    required this.rxcui,
    required this.displayName,
    required this.isApproximate,
  });
}

class RxNavService {
  static const _host = 'rxnav.nlm.nih.gov';
  static const _timeout = Duration(seconds: 10);

  /// Looks up the active ingredient for a US medicine name.
  ///
  /// Exact/normalized matches can be shown immediately. RxNav explicitly
  /// describes approximate results as candidates for manual review, so fuzzy
  /// matches carry their canonical name back to the UI for confirmation.
  static Future<RxNavLookupResult> lookupGeneric(
    String searchTerm, {
    http.Client? client,
  }) async {
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) return const RxNavLookupResult.notFound();

    final requestClient = client ?? http.Client();
    try {
      final match =
          await _findExactMatch(requestClient, trimmed) ??
          await _findApproximateMatch(requestClient, trimmed);
      if (match == null) return const RxNavLookupResult.notFound();

      final ingredientNames = await _findIngredientNames(
        requestClient,
        match.rxcui,
      );
      if (ingredientNames.isEmpty) {
        return const RxNavLookupResult.notFound();
      }

      return RxNavLookupResult.found(
        genericName: ingredientNames.join(' + '),
        matchedMedicineName: match.displayName,
        requiresMatchConfirmation: match.isApproximate,
      );
    } catch (_) {
      // Network failures, non-success responses, timeouts, and malformed
      // remote data all produce one recoverable user-facing state.
      return const RxNavLookupResult.networkError();
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<_RxNavMatch?> _findExactMatch(
    http.Client client,
    String term,
  ) async {
    for (final searchMode in ['1', '2']) {
      final body = await _getJson(
        client,
        Uri.https(_host, '/REST/rxcui.json', {
          'name': term,
          'search': searchMode,
        }),
      );
      final idGroup = body['idGroup'] as Map<String, dynamic>?;
      final ids = idGroup?['rxnormId'] as List?;
      if (ids != null && ids.isNotEmpty) {
        final rxcui = ids.first as String;
        return _RxNavMatch(
          rxcui: rxcui,
          displayName: term,
          isApproximate: false,
        );
      }
    }
    return null;
  }

  static Future<_RxNavMatch?> _findApproximateMatch(
    http.Client client,
    String term,
  ) async {
    final body = await _getJson(
      client,
      Uri.https(_host, '/REST/approximateTerm.json', {
        'term': term,
        'maxEntries': '5',
        'option': '1',
      }),
    );
    final group = body['approximateGroup'] as Map<String, dynamic>?;
    final candidates = group?['candidate'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final parsed = candidates.cast<Map<String, dynamic>>();
    final bestRank = parsed.first['rank'] as String?;
    final bestCandidates = bestRank == null
        ? parsed
        : parsed.where((candidate) => candidate['rank'] == bestRank).toList();
    final candidate = bestCandidates.firstWhere(
      (item) => item['source'] == 'RXNORM' && item['name'] is String,
      orElse: () => bestCandidates.first,
    );
    final rxcui = candidate['rxcui'] as String?;
    if (rxcui == null || rxcui.isEmpty) return null;

    final candidateName = candidate['name'] as String?;
    final displayName =
        (candidateName != null && candidateName.trim().isNotEmpty
        ? candidateName.trim()
        : await _findConceptName(client, rxcui));
    if (displayName == null || displayName.isEmpty) return null;

    return _RxNavMatch(
      rxcui: rxcui,
      displayName: displayName,
      isApproximate: true,
    );
  }

  static Future<String?> _findConceptName(
    http.Client client,
    String rxcui,
  ) async {
    final body = await _getJson(
      client,
      Uri.https(_host, '/REST/rxcui/$rxcui/properties.json'),
    );
    final properties = body['properties'] as Map<String, dynamic>?;
    final name = properties?['name'] as String?;
    return name == null || name.trim().isEmpty ? null : name.trim();
  }

  static Future<List<String>> _findIngredientNames(
    http.Client client,
    String rxcui,
  ) async {
    final body = await _getJson(
      client,
      Uri.https(_host, '/REST/rxcui/$rxcui/related.json', {'tty': 'IN MIN'}),
    );
    final group = body['relatedGroup'] as Map<String, dynamic>?;
    final conceptGroups = group?['conceptGroup'] as List?;
    if (conceptGroups == null) return const [];

    var ingredientNames = <String>[];
    var combinationNames = <String>[];
    for (final rawGroup in conceptGroups) {
      final conceptGroup = rawGroup as Map<String, dynamic>;
      final tty = conceptGroup['tty'] as String?;
      final properties = conceptGroup['conceptProperties'] as List?;
      if (properties == null) continue;
      final names = properties
          .cast<Map<String, dynamic>>()
          .map((item) => item['name'] as String?)
          .whereType<String>()
          .map(_titleCase)
          .toList();
      if (tty == 'IN') {
        ingredientNames = names;
      } else if (tty == 'MIN') {
        combinationNames = names;
      }
    }
    if (ingredientNames.isNotEmpty) return ingredientNames;
    return combinationNames.isEmpty ? const [] : [combinationNames.first];
  }

  static Future<Map<String, dynamic>> _getJson(
    http.Client client,
    Uri uri,
  ) async {
    final response = await client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'RxNav returned HTTP ${response.statusCode}',
        uri,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
