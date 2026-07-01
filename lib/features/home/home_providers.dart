import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/logic/recommendations_match.dart';
import '../../core/providers.dart';
import '../auth/auth_controller.dart';
import '../vod/vod_providers.dart';
import '../series/series_providers.dart';
import '../../services/tmdb/tmdb_providers.dart';

/// Catalogue VOD complet, filtré aux catégories FR (chargé une fois, mis en cache).
final allVodProvider = FutureProvider<List<VodItem>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await ref.watch(vodCategoriesProvider.future);
  final ids = cats.map((e) => e.id).toSet();
  final all = await c.vodStreams();
  return all.where((m) => ids.contains(m.categoryId)).toList();
});

final allSeriesProvider = FutureProvider<List<SeriesItem>>((ref) async {
  final c = ref.watch(xtreamClientProvider);
  if (c == null) return [];
  final cats = await ref.watch(seriesCategoriesProvider.future);
  final ids = cats.map((e) => e.id).toSet();
  final all = await c.seriesList();
  return all.where((s) => ids.contains(s.categoryId)).toList();
});

/// Derniers films ajoutés (tri par `added` décroissant).
final latestVodProvider = FutureProvider<List<VodItem>>((ref) async {
  final all = await ref.watch(allVodProvider.future);
  final list = [...all]..sort((a, b) => b.added.compareTo(a.added));
  return list.take(24).toList();
});

/// Dernières séries ajoutées (tri par `last_modified` décroissant).
final latestSeriesProvider = FutureProvider<List<SeriesItem>>((ref) async {
  final all = await ref.watch(allSeriesProvider.future);
  final list = [...all]..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  return list.take(24).toList();
});

/// Recommandations séries : seeds = séries récemment lues → TMDB tv recommandations
/// → filtrées sur le catalogue séries.
final seriesRecommendationsProvider = FutureProvider<List<SeriesItem>>((ref) async {
  if (ref.watch(authControllerProvider) == null) return [];
  final catalog = await ref.watch(allSeriesProvider.future);
  if (catalog.isEmpty) return [];
  final tmdb = ref.read(tmdbServiceProvider);
  final seeds = ref.read(prefsProvider).recent().where((e) => e.kind == MediaKind.series).take(4).toList();
  if (seeds.isEmpty) return [];
  final seen = <int>{};
  final suggestions = <Map<String, dynamic>>[];
  for (final seed in seeds) {
    final hit = await tmdb.search('tv', seed.name);
    final id = hit?['id'];
    if (id is! int) continue;
    for (final r in await tmdb.recommendations('tv', id)) {
      final rid = r['id'];
      if (rid is! int || seen.contains(rid)) continue;
      seen.add(rid);
      final date = (r['first_air_date'] ?? '').toString();
      suggestions.add({'title': (r['name'] ?? r['title'] ?? '').toString(), 'year': date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null, 'ids': {'tmdb': rid}});
    }
  }
  if (suggestions.isEmpty) return [];
  final catalogMaps = catalog.map((s) => {'name': s.name, '_tmdbId': s.tmdbId, 'releaseDate': null, '__ref': s}).toList();
  return matchRecommendationsToCatalog(suggestions, catalogMaps).map((mp) => mp['__ref'] as SeriesItem).take(24).toList();
});

/// Recommandations films : seeds = films récemment lus → TMDB recommandations →
/// filtrées sur le catalogue (matchRecommendationsToCatalog). Vide si rien à amorcer.
final movieRecommendationsProvider = FutureProvider<List<VodItem>>((ref) async {
  final prefs = ref.watch(authControllerProvider); // recrée si profil change
  if (prefs == null) return [];
  final catalog = await ref.watch(allVodProvider.future);
  if (catalog.isEmpty) return [];
  final tmdb = ref.read(tmdbServiceProvider);

  // Seeds : films récemment lus (max 4), plus la reprise en cours.
  final recentMovies = ref
      .read(prefsProvider)
      .recent()
      .where((e) => e.kind == MediaKind.movie)
      .take(4)
      .toList();
  if (recentMovies.isEmpty) return [];

  // Agrège les recommandations TMDB de chaque seed.
  final seen = <int>{};
  final suggestions = <Map<String, dynamic>>[];
  for (final seed in recentMovies) {
    final hit = await tmdb.search('movie', seed.name);
    final id = hit?['id'];
    if (id is! int) continue;
    final recs = await tmdb.recommendations('movie', id);
    for (final r in recs) {
      final rid = r['id'];
      if (rid is! int || seen.contains(rid)) continue;
      seen.add(rid);
      final date = (r['release_date'] ?? '').toString();
      suggestions.add({
        'title': (r['title'] ?? r['name'] ?? '').toString(),
        'year': date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null,
        'ids': {'tmdb': rid},
      });
    }
  }
  if (suggestions.isEmpty) return [];

  // Matche contre le catalogue (par titre nettoyé + année) et exclut le déjà-vu.
  final catalogMaps = catalog
      .map((m) => {'name': m.name, '_tmdbId': m.tmdbId, 'releaseDate': null, '__ref': m})
      .toList();
  final matched = matchRecommendationsToCatalog(suggestions, catalogMaps);
  final watchedIds = ref.read(prefsProvider).watchedMap().keys.toSet();
  return matched
      .map((mp) => mp['__ref'] as VodItem)
      .where((m) => !watchedIds.contains('movie:${m.streamId}'))
      .take(24)
      .toList();
});
