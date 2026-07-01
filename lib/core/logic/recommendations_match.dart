import 'text_utils.dart';

/// Normalise un item Trakt (plat {title,year,ids} ou enveloppé {movie|show:{...}})
/// en {title, year, tmdbId}.
class TraktNorm {
  final String title;
  final Object? year;
  final int? tmdbId;
  const TraktNorm(this.title, this.year, this.tmdbId);
}

TraktNorm? normalizeTraktItem(Map? item) {
  if (item == null) return null;
  final inner = item['movie'] ?? item['show'] ?? item;
  if (inner is! Map) return null;
  final ids = inner['ids'];
  final tmdb = (ids is Map) ? ids['tmdb'] : null;
  final tmdbId = tmdb == null ? null : int.tryParse(tmdb.toString());
  return TraktNorm((inner['title'] ?? '').toString(), inner['year'], tmdbId);
}

/// Associe des recommandations Trakt/TMDB aux éléments présents dans le catalogue
/// IPTV. Pur : pas de réseau/IO. Match par _tmdbId puis par cleanTitle+année.
List<Map<String, dynamic>> matchRecommendationsToCatalog(
  List<Map<String, dynamic>>? traktItems,
  List<Map<String, dynamic>>? catalogItems,
) {
  final catalog = catalogItems ?? const <Map<String, dynamic>>[];
  final byTmdbId = <int, Map<String, dynamic>>{};
  final byTitleYear = <String, Map<String, dynamic>>{};
  for (final c in catalog) {
    final tmdb = c['_tmdbId'];
    if (tmdb != null) {
      final id = int.tryParse(tmdb.toString());
      if (id != null) byTmdbId.putIfAbsent(id, () => c);
    }
    final rd = c['releaseDate']?.toString();
    final year = (rd != null && rd.length >= 4) ? rd.substring(0, 4) : yearOf(c['name']?.toString());
    final key = '${cleanTitle(c['name']?.toString()).toLowerCase()}|${year.isEmpty ? '' : year}';
    byTitleYear.putIfAbsent(key, () => c);
  }

  final matched = <Map<String, dynamic>>[];
  final seen = <Map<String, dynamic>>{};
  for (final raw in (traktItems ?? const <Map<String, dynamic>>[])) {
    final item = normalizeTraktItem(raw);
    if (item == null || item.title.isEmpty) continue;
    Map<String, dynamic>? catalogItem = item.tmdbId != null ? byTmdbId[item.tmdbId] : null;
    if (catalogItem == null) {
      final yr = item.year == null ? '' : item.year.toString();
      final key = '${cleanTitle(item.title).toLowerCase()}|$yr';
      catalogItem = byTitleYear[key];
    }
    if (catalogItem == null || seen.contains(catalogItem)) continue;
    seen.add(catalogItem);
    matched.add(catalogItem);
  }
  return matched;
}
