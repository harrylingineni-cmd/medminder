import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── US Generic Lookup (RxNav / RxNorm API) ────────────────────────────────
//
// For "United States" mode on the Find Generic screen, we don't have a
// curated local list — instead we ask the US National Library of Medicine's
// free RxNav API, in two steps:
//
//   1. Find the RxCUI (RxNorm Concept Unique Identifier — just an id number
//      RxNorm uses for a specific medicine) for whatever the user typed.
//      We try this two ways, in order:
//        a. rxcui.json — an EXACT name match (tried case/whitespace-exact
//           first via `search=1`, then a normalized exact match via
//           `search=2`). This is precise: it can't wander off to an
//           unrelated concept.
//        b. approximateTerm.json — only if (a) found nothing. This is a
//           fuzzy "closest match" search, used as a fallback for
//           misspellings or less common names.
//
//   2. related — takes that RxCUI and asks "what are this medicine's
//      active ingredients?". We ask for two ingredient types:
//        - IN  = the base ingredient(s) of the SPECIFIC medicine we
//                matched, e.g. Tylenol -> "acetaminophen".
//        - MIN = a "multiple ingredient" combination name RxNorm has
//                already grouped together, e.g. "amoxicillin / clavulanate"
//      We prefer IN — see the long comment on `_findIngredientNames` for
//      why MIN is NOT a safe default here.
//
// No API key is required; this is a public NLM service.

/// What happened when we tried to look up a US brand name's generic.
enum RxNavLookupOutcome {
  found, // We found at least one active ingredient.
  notFound, // The API responded fine, but had no match/ingredients.
  networkError, // Couldn't reach the API, it timed out, or errored.
}

/// The outcome of a US lookup, plus the generic name if one was found.
class RxNavLookupResult {
  final RxNavLookupOutcome outcome;

  /// e.g. "Ibuprofen" or "Amoxicillin / Clavulanate". Only set when
  /// [outcome] is [RxNavLookupOutcome.found].
  final String? genericName;

  /// The exact medicine name RxNav matched the search to, e.g. "Aspirin
  /// 325 MG Oral Tablet". Only set when [outcome] is
  /// [RxNavLookupOutcome.found]. Always shown to the user so they can check
  /// it against their label, but it especially matters when
  /// [isApproximateMatch] is true — that's when it can differ from what
  /// they typed.
  final String? matchedName;

  /// True when RxNav couldn't find an exact name match and this is its
  /// closest guess instead (see `_findClosestRxcui`). The UI must not show
  /// the generic ingredient for an approximate match until the user has
  /// confirmed [matchedName] is actually their medicine.
  final bool isApproximateMatch;

  const RxNavLookupResult._(
    this.outcome,
    this.genericName,
    this.matchedName,
    this.isApproximateMatch,
  );

  const RxNavLookupResult.found({
    required String genericName,
    required String matchedName,
    bool isApproximateMatch = false,
  }) : this._(RxNavLookupOutcome.found, genericName, matchedName, isApproximateMatch);

  const RxNavLookupResult.notFound()
    : this._(RxNavLookupOutcome.notFound, null, null, false);

  const RxNavLookupResult.networkError()
    : this._(RxNavLookupOutcome.networkError, null, null, false);
}

class RxNavService {
  static const _baseUrl = 'https://rxnav.nlm.nih.gov/REST';

  // Don't let a slow/hung connection leave the user staring at a spinner
  // forever — give up and show an error after this long.
  static const _timeout = Duration(seconds: 10);

  /// Looks up the generic (active ingredient) name for a US brand/medicine
  /// name typed by the user, e.g. "Advil" -> "Ibuprofen".
  static Future<RxNavLookupResult> lookupGeneric(String searchTerm) async {
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) return const RxNavLookupResult.notFound();

    try {
      final exactRxcui = await _findExactRxcui(trimmed);
      final String rxcui;
      final String matchedName;
      final bool isApproximate;
      if (exactRxcui != null) {
        rxcui = exactRxcui;
        matchedName = trimmed;
        isApproximate = false;
      } else {
        final closest = await _findClosestRxcui(trimmed);
        if (closest == null) return const RxNavLookupResult.notFound();
        rxcui = closest.rxcui;
        matchedName = closest.name;
        isApproximate = true;
      }

      final ingredientNames = await _findIngredientNames(rxcui);
      if (ingredientNames.isEmpty) return const RxNavLookupResult.notFound();

      return RxNavLookupResult.found(
        genericName: ingredientNames.join(' + '),
        matchedName: matchedName,
        isApproximateMatch: isApproximate,
      );
    } on Exception {
      // Covers: no internet connection, DNS failure, request timeout, or an
      // unexpected/malformed response we couldn't parse. We deliberately
      // treat all of these the same way on screen — "couldn't reach the
      // service, please try again" — rather than showing a technical error.
      return const RxNavLookupResult.networkError();
    }
  }

  /// Step 1a (preferred): `https://rxnav.nlm.nih.gov/REST/rxcui.json`
  /// Looks for an EXACT match of [term] against RxNorm's medicine names.
  /// Tries `search=1` (exact string match) first, then `search=2`
  /// (normalized — case/whitespace-insensitive — exact match) if that
  /// finds nothing. Returns null if neither finds a match.
  ///
  /// This is what fixes searches like "Aspirin" going wrong: an exact name
  /// match always lands on the medicine the user actually meant, whereas
  /// `approximateTerm`'s fuzzy scoring can occasionally rank a similarly
  /// spelled but unrelated concept above it.
  static Future<String?> _findExactRxcui(String term) async {
    for (final searchMode in ['1', '2']) {
      final uri = Uri.parse(
        '$_baseUrl/rxcui.json'
        '?name=${Uri.encodeQueryComponent(term)}&search=$searchMode',
      );
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) continue;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final idGroup = body['idGroup'] as Map<String, dynamic>?;
      final ids = idGroup?['rxnormId'] as List?;
      if (ids != null && ids.isNotEmpty) return ids.first as String;
    }
    return null;
  }

  /// Step 1b (fallback): https://rxnav.nlm.nih.gov/REST/approximateTerm.json
  /// Only called when `_findExactRxcui` found nothing. Finds the RxCUI that
  /// most closely matches [term], for mis-spelled or less common names, and
  /// then looks up that concept's actual RxNorm name — approximateTerm.json
  /// doesn't return a name itself, only an id and a score. Returns null if
  /// nothing matched.
  ///
  /// Callers must treat the result as a candidate to confirm with the user,
  /// not a definite answer — see [RxNavLookupResult.isApproximateMatch].
  static Future<({String rxcui, String name})?> _findClosestRxcui(
    String term,
  ) async {
    final searchUri = Uri.parse(
      '$_baseUrl/approximateTerm.json'
      '?term=${Uri.encodeQueryComponent(term)}&maxEntries=1',
    );
    final searchResponse = await http.get(searchUri).timeout(_timeout);
    if (searchResponse.statusCode != 200) return null;

    final searchBody = jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final group = searchBody['approximateGroup'] as Map<String, dynamic>?;
    final candidates = group?['candidate'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final firstCandidate = candidates.first as Map<String, dynamic>;
    final rxcui = firstCandidate['rxcui'] as String?;
    if (rxcui == null) return null;

    final nameUri = Uri.parse('$_baseUrl/rxcui/$rxcui/properties.json');
    final nameResponse = await http.get(nameUri).timeout(_timeout);
    if (nameResponse.statusCode != 200) return null;

    final nameBody = jsonDecode(nameResponse.body) as Map<String, dynamic>;
    final properties = nameBody['properties'] as Map<String, dynamic>?;
    final name = properties?['name'] as String?;
    if (name == null || name.trim().isEmpty) return null;

    return (rxcui: rxcui, name: name.trim());
  }

  /// Step 2: `https://rxnav.nlm.nih.gov/REST/rxcui/<rxcui>/related.json?tty=IN+MIN`
  /// Finds the active-ingredient name(s) for the medicine identified by
  /// [rxcui].
  ///
  /// We prefer the IN (base ingredient) group over MIN, and this matters a
  /// lot more than it sounds like it should. Concretely, here's the bug
  /// this avoids: searching "Aspirin" resolves to RxCUI 1191 — which *is*
  /// the ingredient concept for aspirin itself. Asking RxNav for THAT
  /// concept's related MIN group doesn't return "aspirin's combination
  /// products" in any narrow sense — it returns every multi-ingredient
  /// combination in RxNorm that happens to contain aspirin as one of its
  /// actives: "aluminum hydroxide / aspirin / caffeine", "aspirin /
  /// quinine", "aspirin / pyridinolcarbamate", dozens more. Preferring MIN
  /// meant we'd join ALL of those into one giant, wrong "generic name".
  ///
  /// The IN group doesn't have this problem: it always reflects exactly the
  /// ingredient(s) of the ONE specific medicine concept we matched — a
  /// single ingredient for a plain drug (Tylenol -> ["acetaminophen"]), or
  /// several for a genuine combination product searched by its own name
  /// (Excedrin -> ["aspirin", "acetaminophen", "caffeine"]). That's exactly
  /// the "only show multiple ingredients when it's genuinely a combination
  /// the user searched for" behavior we want, with no extra logic needed.
  static Future<List<String>> _findIngredientNames(String rxcui) async {
    final uri = Uri.parse('$_baseUrl/rxcui/$rxcui/related.json?tty=IN+MIN');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final group = body['relatedGroup'] as Map<String, dynamic>?;
    final conceptGroups = group?['conceptGroup'] as List?;
    if (conceptGroups == null) return const [];

    var singleIngredientNames = <String>[];
    var combinationNames = <String>[];

    for (final rawGroup in conceptGroups) {
      final conceptGroup = rawGroup as Map<String, dynamic>;
      final tty = conceptGroup['tty'] as String?;
      final properties = conceptGroup['conceptProperties'] as List?;
      if (properties == null) continue;

      final names = properties
          .map((p) => (p as Map<String, dynamic>)['name'] as String?)
          .whereType<String>()
          .map(_titleCase)
          .toList();

      if (tty == 'MIN') {
        combinationNames = names;
      } else if (tty == 'IN') {
        singleIngredientNames = names;
      }
    }

    if (singleIngredientNames.isNotEmpty) return singleIngredientNames;

    // Fall back to MIN only when a medicine has no IN entries at all (rare
    // in practice). Take just the single closest MIN name rather than
    // every one RxNav returns — if several come back, we've likely hit the
    // same "anchored on a bare ingredient" case described above, and one
    // plausible answer beats a wall of unrelated combination names.
    return combinationNames.isEmpty ? const [] : [combinationNames.first];
  }

  /// RxNav returns ingredient names in lowercase (e.g. "ibuprofen"). This
  /// capitalizes the first letter of each word so it matches the rest of
  /// the app's display style, e.g. "Ibuprofen" or "Amoxicillin / Clavulanate".
  static String _titleCase(String value) {
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
