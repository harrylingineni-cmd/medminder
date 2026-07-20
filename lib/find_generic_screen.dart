import 'package:flutter/material.dart';
import 'generic_medicine_data.dart';
import 'rxnav_service.dart';

// ─── Find Generic Screen ───────────────────────────────────────────────────
//
// Helps the user find the cheaper GENERIC (same active ingredient) version
// of a brand-name medicine they type in.
//
//   - India mode looks the brand up in `generic_medicine_data.dart`, a
//     small curated list built into the app — works instantly, no internet
//     needed.
//   - United States mode calls the free RxNav API (see `rxnav_service.dart`)
//     over the internet, since there's no equivalent small curated list for
//     the huge number of US brand names.
//
// This screen never suggests switching medicines on its own — it always
// pairs the result with a disclaimer to confirm with a doctor/pharmacist
// first (see `_buildDisclaimer` below).

/// Which country's medicine names we're searching. India uses our local
/// list; United States calls the live RxNav API.
enum _Country { india, unitedStates }

/// What the result area below the search box should currently show.
enum _LookupStatus { idle, loading, confirmMatch, found, notFound, error }

class FindGenericScreen extends StatefulWidget {
  const FindGenericScreen({super.key});

  @override
  State<FindGenericScreen> createState() => _FindGenericScreenState();
}

class _FindGenericScreenState extends State<FindGenericScreen> {
  final _searchController = TextEditingController();

  _Country _country = _Country.india; // India is the default, per spec.
  _LookupStatus _status = _LookupStatus.idle;

  // The brand name we last actually searched for, and what we found (if
  // anything) — kept separately from the live text field so the result
  // card doesn't change while the user is still typing their NEXT search.
  String _searchedBrand = '';
  String? _genericResult;

  // The exact medicine name RxNav (or the India list) matched to. Shown in
  // the result card, and — for an approximate US match — shown on its own
  // in a confirmation step before the generic ingredient is ever revealed.
  String? _matchedMedicineName;

  // Live "did you mean...?" suggestions shown under the search box as the
  // user types. Only used in India mode, since that's the only list we can
  // search instantly/offline; US mode has nothing to suggest from locally.
  List<String> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _onCountryChanged(_Country country) {
    if (country == _country) return;
    setState(() {
      _country = country;
      _status = _LookupStatus.idle;
      _matchedMedicineName = null;
      _suggestions = [];
      _searchController.clear();
    });
  }

  void _onSearchTextChanged(String value) {
    setState(() {
      _suggestions = _country == _Country.india
          ? suggestIndiaBrandNames(value)
          : const [];
    });
  }

  /// Runs a search using whatever's in the search box, or — when a
  /// suggestion is tapped — using [brandNameOverride] instead, filling the
  /// search box with it first.
  void _searchIndia([String? brandNameOverride]) {
    final rawInput = brandNameOverride ?? _searchController.text;
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return;
    if (brandNameOverride != null) {
      _searchController.text = brandNameOverride;
    }

    final generic = findIndiaGeneric(trimmed);
    setState(() {
      _searchedBrand = trimmed;
      _genericResult = generic;
      _matchedMedicineName = trimmed;
      _status = generic != null
          ? _LookupStatus.found
          : _LookupStatus.notFound;
      _suggestions = [];
    });
  }

  /// Calls the RxNav API (via RxNavService) for US mode. This is async and
  /// hits the network, so we show a loading spinner while it's in flight
  /// and handle the not-found / network-error cases explicitly.
  Future<void> _searchUnitedStates() async {
    final trimmed = _searchController.text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _searchedBrand = trimmed;
      _matchedMedicineName = null;
      _status = _LookupStatus.loading;
    });

    final result = await RxNavService.lookupGeneric(trimmed);
    if (!mounted) return; // Screen may have been closed while we waited.

    setState(() {
      switch (result.outcome) {
        case RxNavLookupOutcome.found:
          _genericResult = result.genericName;
          _matchedMedicineName = result.matchedName;
          // An approximate match is RxNav's best guess, not a confirmed
          // answer — the generic ingredient must stay hidden until the
          // user has checked the matched name against their own label.
          _status = result.isApproximateMatch
              ? _LookupStatus.confirmMatch
              : _LookupStatus.found;
        case RxNavLookupOutcome.notFound:
          _genericResult = null;
          _status = _LookupStatus.notFound;
        case RxNavLookupOutcome.networkError:
          _genericResult = null;
          _status = _LookupStatus.error;
      }
    });
  }

  /// User tapped "Yes, this is my medicine" on the approximate-match
  /// confirmation card — now it's safe to reveal the generic ingredient.
  void _confirmMatchedMedicine() {
    setState(() => _status = _LookupStatus.found);
  }

  /// User tapped "No, search again" — go back to not-found rather than
  /// showing a possibly-wrong generic ingredient.
  void _rejectMatchedMedicine() {
    setState(() {
      _status = _LookupStatus.notFound;
      _genericResult = null;
      _matchedMedicineName = null;
    });
  }

  void _onSearchPressed() {
    FocusScope.of(context).unfocus(); // Hide the keyboard once they search.
    if (_country == _Country.india) {
      _searchIndia();
    } else {
      _searchUnitedStates();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4B8C),
        foregroundColor: Colors.white,
        title: const Text(
          'Find Generic',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Country',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildCountryToggle(),
              const SizedBox(height: 26),

              const Text(
                'Medicine Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildSearchBox(),
              _buildSuggestions(),
              _buildResultArea(),
              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  /// The India / United States toggle, styled to match the "Even Intervals
  /// / Custom Times" toggle already used on the Add Medication screen, so
  /// the whole app feels consistent.
  Widget _buildCountryToggle() {
    return Row(
      children: [
        Expanded(
          child: _countryButton('India', _Country.india),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _countryButton('United States', _Country.unitedStates),
        ),
      ],
    );
  }

  Widget _countryButton(String label, _Country country) {
    final selected = _country == country;
    return OutlinedButton(
      onPressed: () => _onCountryChanged(country),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF1A4B8C) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF1A4B8C),
        side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// The large search box plus a big, clearly-labelled Search button below
  /// it (rather than relying only on the keyboard's tiny search key, which
  /// can be hard to tap precisely).
  Widget _buildSearchBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 22),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchTextChanged,
          onSubmitted: (_) => _onSearchPressed(),
          decoration: InputDecoration(
            hintText: 'Type a medicine name',
            hintStyle: const TextStyle(fontSize: 20, color: Colors.black45),
            prefixIcon: const Icon(Icons.search, size: 28),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 26),
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                        _status = _LookupStatus.idle;
                        _matchedMedicineName = null;
                      });
                    },
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _status == _LookupStatus.loading
                ? null
                : _onSearchPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A4B8C),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1A4B8C),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.search, size: 26),
            label: const Text(
              'Search',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// India-mode "did you mean...?" list. Tapping a suggestion immediately
  /// searches for it, saving the user from having to type the whole name
  /// and get the spelling exactly right.
  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _suggestions
            .map(
              (brand) => ListTile(
                title: Text(brand, style: const TextStyle(fontSize: 20)),
                trailing: const Icon(Icons.north_west, size: 20),
                onTap: () => _searchIndia(brand),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildResultArea() {
    switch (_status) {
      case _LookupStatus.idle:
        return const SizedBox.shrink();
      case _LookupStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        );
      case _LookupStatus.confirmMatch:
        return _buildConfirmMatchCard();
      case _LookupStatus.found:
        return _buildFoundCard();
      case _LookupStatus.notFound:
        return _buildNotFoundCard();
      case _LookupStatus.error:
        return _buildErrorCard();
    }
  }

  /// Shown only for an approximate US match, before the generic ingredient
  /// is revealed. Large text and two big, clearly-labelled buttons — no
  /// small print to misread, no default selected so a stray tap can't
  /// accidentally confirm the wrong medicine.
  Widget _buildConfirmMatchCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCC7A00), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange.shade900, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Is this your medicine?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'We could not find an exact match for what you typed. This is '
            'the closest medicine name we found:',
            style: TextStyle(fontSize: 17, height: 1.4),
          ),
          const SizedBox(height: 14),
          _buildNameBlock(
            label: 'Closest match found',
            name: _matchedMedicineName ?? '',
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmMatchedMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, this is my medicine',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _rejectMatchedMedicine,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A4B8C),
                side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'No, that is not it',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The main "swap" result: brand name on top, an arrow, then the generic
  /// (active ingredient) below it, in a large, easy-to-read card.
  Widget _buildFoundCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A4B8C), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNameBlock(
            label: _country == _Country.unitedStates
                ? 'Medicine matched'
                : 'Brand name you searched',
            name: _matchedMedicineName ?? _searchedBrand,
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 10),
          const Center(
            child: Icon(
              Icons.arrow_downward,
              size: 34,
              color: Color(0xFF1A4B8C),
            ),
          ),
          const SizedBox(height: 10),
          _buildNameBlock(
            label: 'Generic (active ingredient)',
            name: _genericResult ?? '',
            icon: Icons.check_circle,
            emphasize: true,
          ),
          const SizedBox(height: 18),
          const Text(
            'Same active ingredient — it works the same way in the body, '
            'and usually costs less.',
            style: TextStyle(fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(
                Icons.local_pharmacy_outlined,
                size: 24,
                color: Color(0xFF1A4B8C),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ask your pharmacist for the generic version.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameBlock({
    required String label,
    required String name,
    required IconData icon,
    bool emphasize = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1A4B8C)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: emphasize ? 26 : 22,
              fontWeight: FontWeight.bold,
              color: emphasize ? Colors.green.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the brand wasn't found — in India mode this means it's not
  /// in our curated list yet; in US mode it means RxNav had no match.
  Widget _buildNotFoundCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_off, size: 28, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We couldn\'t find "$_searchedBrand"',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _country == _Country.india
                ? 'Please check the spelling. This app currently covers a '
                      'starting list of common Indian brands — ask your '
                      'pharmacist if this one isn\'t listed yet.'
                : 'Please check the spelling and try again, or ask your '
                      'pharmacist.',
            style: const TextStyle(
              fontSize: 17,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the US lookup couldn't reach RxNav at all (no internet,
  /// timed out, etc.) — distinct from "not found" because here we genuinely
  /// don't know the answer, rather than knowing there's no match.
  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, size: 28, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Couldn\'t reach the lookup service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your internet connection and try again.',
            style: TextStyle(fontSize: 17, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _onSearchPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 24),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A permanent, always-visible safety disclaimer — shown whether or not
  /// the user has searched yet, styled to match the amber disclaimer box on
  /// the Welcome screen so the app is consistent about how it flags
  /// important safety information.
  Widget _buildDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCC7A00), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade900, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'For Information Only',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This tool is for information only and is not medical advice. '
            '"Same active ingredient" means the medicines work the same way '
            'in the body — but brands can still differ in inactive '
            'ingredients, dose form, or manufacturer. Always confirm with '
            'your doctor or pharmacist before switching medicines.',
            style: TextStyle(fontSize: 17, height: 1.5),
          ),
        ],
      ),
    );
  }
}
