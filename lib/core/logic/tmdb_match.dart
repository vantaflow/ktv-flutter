import 'text_utils.dart';

/// Port Dart de lib/tmdb-match.js — choisit le meilleur résultat TMDB dont le
/// titre correspond vraiment à la requête (évite les fausses affiches).
/// Renvoie null si aucun candidat n'atteint le seuil de confiance (score >= 60).
Map<String, dynamic>? ktvPickResult(
  List<Map<String, dynamic>>? results,
  String query, [
  Object? year,
]) {
  final qn = ktvNormTitle(query);
  if (qn.isEmpty) return null;
  Map<String, dynamic>? best;
  double bestScore = -1;
  for (final r in (results ?? const <Map<String, dynamic>>[]).take(8)) {
    final titles = [r['title'], r['original_title'], r['name'], r['original_name']]
        .where((t) => t != null)
        .map((t) => ktvNormTitle(t.toString()))
        .toList();
    double s = 0;
    for (final t in titles) {
      if (t.isEmpty) continue;
      if (t == qn) {
        s = s > 100 ? s : 100;
      } else if (t.startsWith('$qn ') || qn.startsWith('$t ')) {
        s = s > 85 ? s : 85;
      } else if (t.contains(qn) || qn.contains(t)) {
        s = s > 62 ? s : 62;
      }
    }
    if (s <= 0) continue;
    if (r['poster_path'] != null) s += 4;
    if (r['overview'] != null) s += 2;
    final pop = (r['popularity'] is num) ? (r['popularity'] as num).toDouble() : 0.0;
    final popBonus = pop / 15;
    s += popBonus < 6 ? popBonus : 6;
    final ry = ((r['release_date'] ?? r['first_air_date'] ?? '') as String);
    final ry4 = ry.length >= 4 ? ry.substring(0, 4) : ry;
    if (year != null && '$year'.isNotEmpty && ry4.isNotEmpty && '$year' == ry4) s += 12;
    if (s > bestScore) {
      bestScore = s;
      best = r;
    }
  }
  return bestScore >= 60 ? best : null;
}
