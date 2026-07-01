import 'package:diacritic/diacritic.dart';

/// Port Dart de lib/text-utils.js (KTV Electron) — logique pure, testée.
/// Nettoyage/normalisation de titres et filtres de catégories.

/// Année (19xx/20xx) trouvée dans un nom, sinon chaîne vide.
String yearOf(String? name) {
  final m = RegExp(r'\b(19|20)\d{2}\b').firstMatch(name ?? '');
  return m?.group(0) ?? '';
}

/// Catégories LIVE autorisées : France, Maroc, beIN Sports Arabe (pas TR).
bool categoryAllowed(String? name) {
  final raw = name ?? '';
  final n = raw.toUpperCase();
  if (n.startsWith('FR|')) return true;
  if (n.contains('MOROCCO') || raw.contains('المغرب')) return true;
  if (n.startsWith('AR|') && n.contains('BEIN SPORTS')) return true;
  return false;
}

/// Films/séries : ne garder que les catégories françaises.
bool frCategoryAllowed(String? name) {
  final n = (name ?? '').toUpperCase().trim();
  return n.startsWith('FR|') ||
      n.startsWith('FR ') ||
      n.startsWith('FR-') ||
      n.startsWith('FR_') ||
      n == 'FR' ||
      n.contains('FRANCE') ||
      n.contains('FRENCH') ||
      n.contains('FRANÇAIS') ||
      n.contains('VOSTFR') ||
      n.contains('TRUEFRENCH');
}

/// Détecte les fausses entrées (séparateurs "###", symboles seuls…).
bool isJunkChannel(String? name) {
  final n = (name ?? '').trim();
  if (n.isEmpty) return true;
  if (n.contains('##') || n.contains('===') || n.contains('▬') || n.contains('●●')) return true;
  if (!RegExp(r'[A-Za-z0-9À-ÿ؀-ۿ]').hasMatch(n)) return true; // que des symboles
  return false;
}

/// Nettoie un titre VOD (retire tags qualité, exposants, année, préfixes, emojis).
String cleanTitle(String? name) {
  final original = (name ?? '').trim();
  var s = name ?? '';
  s = s.replaceAll(RegExp(r'[ᴴᴰᵁᴷᶠˢᴾᴿᴬᵂʰᵉᵛᶜᵖᵈᴺᴹᵃⁿᵗʜᴅ⁰¹²³⁴⁵⁶⁷⁸⁹]'), ' '); // exposants
  // Préfixes courts empilés ("4K-FR - ", "VOD: ", "FR | ").
  String prev;
  do {
    prev = s;
    s = s.replaceFirst(RegExp(r'^\s*[A-Za-z0-9]{1,4}\s*[-|:•▎–]\s*'), '');
  } while (s != prev);
  s = s.replaceAll(RegExp(r'[\[\(][^\]\)]*[\]\)]'), ' '); // (...) [..]
  s = s.replaceAll(RegExp(r'\b(19|20)\d{2}\b'), ' '); // année
  s = s.replaceAll(RegExp(r'\b\d{3,4}p\b', caseSensitive: false), ' '); // 2160p / 1080p
  s = s.replaceAll(
    RegExp(
      r"\b(4K|8K|UHD|QHD|FHD|HD|SD|HDR10?|HDR|DV|DOLBY|ATMOS|IMAX|REMUX|BLU[\-\. ]?RAY|BDRIP|BRRIP|WEB[\-\. ]?RIP|WEB[\-\. ]?DL|HDRIP|DVD[\-\. ]?RIP|AMZN|NF|DSNP|ATVP|MAX|MULTI|VFF|VFQ|VF2|VFI|VOF|VF|VO|VOST(?:FR)?|TRUE[\-\. ]?FRENCH|SUB[\-\. ]?FRENCH|FRENCH|H\.?264|H\.?265|X264|X265|HEVC|AVC|AAC|AC3|EAC3|DTS|DDP?5\.1|10\s?BITS?)\b",
      caseSensitive: false,
    ),
    ' ',
  );
  s = s.replaceAll(RegExp(r'[._]+'), ' ');
  s = s.replaceAll(RegExp(r"[^\p{L}\p{N} :!?'&-]", unicode: true), ' '); // emojis/symboles
  s = s.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(RegExp(r'^[\s:–·\-]+|[\s:–·\-]+$'), '').trim();
  return s.isNotEmpty ? s : original;
}

/// Normalise un titre pour comparaison (sans accents/ponctuation/casse).
String ktvNormTitle(String? s) {
  return removeDiacritics((s ?? '').toLowerCase())
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
