// ─── India Curated Brand → Generic Data ────────────────────────────────────
//
// This is a hand-checked list of common Indian medicine BRAND names mapped
// to their GENERIC name (the active ingredient(s) inside them). It powers
// India mode on the "Find Generic" screen, so lookups work instantly and
// offline — no internet needed, unlike US mode which calls a live API.
//
// IMPORTANT: accuracy matters here, since this is health information.
//   - Keys are brand names as commonly printed on Indian medicine strips.
//   - Values are the generic/active-ingredient name(s). Where a brand is a
//     COMBINATION product (more than one active ingredient), the value
//     lists all of them joined with " + ", e.g. "Ibuprofen + Paracetamol".
//   - This list is intentionally small to start. Add more entries below,
//     following the same "Brand: 'Generic'" pattern, and double-check each
//     one against the strip/packaging or a pharmacist before adding it.
//   - This is NOT a substitute for a doctor/pharmacist — see the disclaimer
//     shown on the Find Generic screen.
const Map<String, String> indiaBrandToGeneric = {
  // ── Pain relief / fever ──
  'Crocin': 'Paracetamol',
  'Dolo': 'Paracetamol',
  'Calpol': 'Paracetamol',
  'Combiflam': 'Ibuprofen + Paracetamol',
  'Brufen': 'Ibuprofen',
  'Ecosprin': 'Aspirin (low dose)',
  'Disprin': 'Aspirin',

  // ── Diabetes ──
  'Glycomet': 'Metformin',
  'Januvia': 'Sitagliptin',
  'Glimestar': 'Glimepiride',

  // ── Antibiotics ──
  'Augmentin': 'Amoxicillin + Clavulanic acid',
  'Azithral': 'Azithromycin',
  'Azee': 'Azithromycin',
  'Zifi': 'Cefixime',
  'Metrogyl': 'Metronidazole',
  'Cifran': 'Ciprofloxacin',

  // ── Stomach / acidity ──
  'Pan': 'Pantoprazole',
  'Pantop': 'Pantoprazole',
  'Omez': 'Omeprazole',

  // ── Blood pressure / heart ──
  'Telma': 'Telmisartan',
  'Amlong': 'Amlodipine',
  'Amlokind': 'Amlodipine',
  'Metolar': 'Metoprolol',

  // ── Cholesterol ──
  'Storvas': 'Atorvastatin',
  'Atorva': 'Atorvastatin',
  'Rosuvas': 'Rosuvastatin',

  // ── Thyroid ──
  'Thyronorm': 'Levothyroxine',
  'Eltroxin': 'Levothyroxine',

  // ── Allergy ──
  'Allegra': 'Fexofenadine',
  'Montek': 'Montelukast',
  'Cetzine': 'Cetirizine',

  // ── Supplements ──
  'Shelcal': 'Calcium + Vitamin D3',
};

/// Looks up the generic name for [brandName] in the India list.
///
/// Matching is case-insensitive and trims extra spaces, so "  crocin" and
/// "CROCIN" both find "Crocin". Returns null if the brand isn't in our list.
String? findIndiaGeneric(String brandName) {
  final query = brandName.trim().toLowerCase();
  if (query.isEmpty) return null;
  for (final entry in indiaBrandToGeneric.entries) {
    if (entry.key.toLowerCase() == query) {
      return entry.value;
    }
  }
  return null;
}

/// Returns up to [limit] brand names that START WITH [query] (case
/// insensitive), sorted alphabetically. Used to show live "did you mean...?"
/// suggestions as the user types, since older adults may not remember the
/// exact spelling of a brand name.
List<String> suggestIndiaBrandNames(String query, {int limit = 6}) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return const [];
  final matches =
      indiaBrandToGeneric.keys
          .where((brand) => brand.toLowerCase().startsWith(trimmed))
          .toList()
        ..sort();
  return matches.take(limit).toList();
}
