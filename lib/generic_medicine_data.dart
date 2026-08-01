// ─── India Curated Brand → Generic Data ────────────────────────────────────
//
// This is a hand-checked list of common Indian medicine BRAND names mapped
// to their GENERIC name (the active ingredient(s) inside them). It powers
// India mode on the "Find Ingredient" screen, so lookups work instantly and
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
//     shown on the Find Ingredient screen.
const Map<String, String> indiaBrandToGeneric = {
  // ── Pain relief / fever ──
  'Brufen': 'Ibuprofen',
  'Calpol': 'Paracetamol',
  'Combiflam': 'Ibuprofen + Paracetamol',
  'Crocin': 'Paracetamol',
  'Disprin': 'Aspirin',
  'Dolo': 'Paracetamol',
  'Ecosprin': 'Aspirin (low dose)',
  'Etova': 'Etoricoxib',
  'Hifenac': 'Aceclofenac',
  'Meftal': 'Mefenamic acid',
  'Naprosyn': 'Naproxen',
  'Nise': 'Nimesulide',
  'Tramazac': 'Tramadol',
  'Ultracet': 'Tramadol + Paracetamol',
  'Voveran': 'Diclofenac',
  'Zerodol': 'Aceclofenac',

  // ── Diabetes ──
  'Amaryl': 'Glimepiride',
  'Galvus': 'Vildagliptin',
  'Glimestar': 'Glimepiride',
  'Glycomet': 'Metformin',
  'Jardiance': 'Empagliflozin',
  'Januvia': 'Sitagliptin',

  // ── Antibiotics ──
  'Augmentin': 'Amoxicillin + Clavulanic acid',
  'Azee': 'Azithromycin',
  'Azithral': 'Azithromycin',
  'Cifran': 'Ciprofloxacin',
  'Ciplox': 'Ciprofloxacin',
  'Doxy-1': 'Doxycycline',
  'Flagyl': 'Metronidazole',
  'Levoflox': 'Levofloxacin',
  'Metrogyl': 'Metronidazole',
  'Monocef': 'Ceftriaxone',
  'Mox': 'Amoxicillin',
  'Novamox': 'Amoxicillin',
  'Taxim-O': 'Cefixime',
  'Zifi': 'Cefixime',

  // ── Stomach / acidity ──
  'Nexpro': 'Esomeprazole',
  'Omez': 'Omeprazole',
  'Pan': 'Pantoprazole',
  'Pantop': 'Pantoprazole',
  'Razo': 'Rabeprazole',
  'Sompraz': 'Esomeprazole',

  // ── Stomach cramps (antispasmodic) ──
  'Buscopan': 'Hyoscine butylbromide',
  'Cyclopam': 'Dicyclomine + Paracetamol',

  // ── Nausea / vomiting ──
  'Domstal': 'Domperidone',
  'Emeset': 'Ondansetron',
  'Ondem': 'Ondansetron',
  'Perinorm': 'Metoclopramide',

  // ── Constipation (laxatives / fibre) ──
  'Duphalac': 'Lactulose',
  'Isabgol': 'Psyllium husk',

  // ── Blood pressure / heart ──
  'Amlokind': 'Amlodipine',
  'Amlong': 'Amlodipine',
  'Ciplar': 'Propranolol',
  'Concor': 'Bisoprolol',
  'Dytor': 'Torsemide',
  'Envas': 'Enalapril',
  'Lasix': 'Furosemide',
  'Losar': 'Losartan',
  'Metolar': 'Metoprolol',
  'Stamlo': 'Amlodipine',
  'Telma': 'Telmisartan',

  // ── Blood thinners ──
  'Clopilet': 'Clopidogrel',
  'Deplatt': 'Clopidogrel',

  // ── Cholesterol ──
  'Atorva': 'Atorvastatin',
  'Crestor': 'Rosuvastatin',
  'Rosuvas': 'Rosuvastatin',
  'Storvas': 'Atorvastatin',

  // ── Thyroid ──
  'Eltroxin': 'Levothyroxine',
  'Thyronorm': 'Levothyroxine',

  // ── Allergy ──
  'Alerid': 'Cetirizine',
  'Allegra': 'Fexofenadine',
  'Avil': 'Pheniramine',
  'Cetzine': 'Cetirizine',
  'Montek': 'Montelukast',

  // ── Asthma / breathing ──
  'Asthalin': 'Salbutamol',
  'Budecort': 'Budesonide',
  'Foracort': 'Formoterol + Budesonide',
  'Seroflo': 'Salmeterol + Fluticasone',

  // ── Mental health / sleep ──
  'Alprax': 'Alprazolam',
  'Clonotril': 'Clonazepam',
  'Nexito': 'Escitalopram',
  'Prodep': 'Fluoxetine',
  'Restyl': 'Alprazolam',
  'Zolfresh': 'Zolpidem',

  // ── Nerve pain / seizures ──
  'Encorate': 'Valproate',
  'Eptoin': 'Phenytoin',
  'Gabapin': 'Gabapentin',
  'Levera': 'Levetiracetam',
  'Pregabid': 'Pregabalin',

  // ── Supplements ──
  'Becosules': 'Vitamin B complex + C',
  'Evion': 'Vitamin E',
  'Folvite': 'Folic acid',
  'Limcee': 'Vitamin C',
  'Neurobion': 'Vitamin B complex',
  'Shelcal': 'Calcium + Vitamin D3',

  // ── Skin ──
  'Betnovate': 'Betamethasone',
  'Candid': 'Clotrimazole',
  'Soframycin': 'Framycetin',
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
