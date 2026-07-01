import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/logic/recommendations_match.dart';
import '../../core/providers.dart';
import '../auth/auth_controller.dart';
import '../vod/vod_providers.dart';
import '../series/series_providers.dart';
import '../../services/tmdb/tmdb_providers.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/epg/epg_providers.dart';

/// Rafraîchissement périodique en arrière-plan (catalogue + EPG) selon le réglage
/// `autoRefreshMin`. L'état = minutes courantes (0 = désactivé).
class AutoRefreshController extends Notifier<int> {
  Timer? _timer;
  @override
  int build() {
    final m = int.tryParse(ref.read(prefsProvider).settingStr('autoRefreshMin', '0')) ?? 0;
    _schedule(m);
    ref.onDispose(() => _timer?.cancel());
    return m;
  }

  Future<void> setMinutes(int m) async {
    await ref.read(prefsProvider).setSetting('autoRefreshMin', m);
    state = m;
    _schedule(m);
  }

  void refreshNow() {
    ref.invalidate(allVodProvider);
    ref.invalidate(allSeriesProvider);
    ref.invalidate(latestVodProvider);
    ref.invalidate(latestSeriesProvider);
    ref.invalidate(epgIndexProvider);
    ref.read(prefsProvider).setSetting('lastRefresh', DateTime.now().millisecondsSinceEpoch);
  }

  void _schedule(int m) {
    _timer?.cancel();
    if (m > 0) _timer = Timer.periodic(Duration(minutes: m), (_) => refreshNow());
  }
}

final autoRefreshControllerProvider = NotifierProvider<AutoRefreshController, int>(AutoRefreshController.new);

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

/// Amorces de recommandation tirées du PROPRE catalogue IPTV de l'utilisateur :
/// les titres les mieux notés (à défaut les plus récents). Ainsi les
/// recommandations sont fondées sur le contenu réellement disponible chez lui.
List<String> _catalogSeedNames(Iterable<({String name, double rating, int added})> items, {int n = 12}) {
  final list = items.toList();
  // Priorité aux titres notés (qualité), sinon aux plus récemment ajoutés.
  final rated = list.where((e) => e.rating > 0).toList()..sort((a, b) => b.rating.compareTo(a.rating));
  final pool = rated.length >= n ? rated : (list..sort((a, b) => b.added.compareTo(a.added)));
  return pool.take(n).map((e) => e.name).toList();
}

/// Transforme un résultat TMDB brut en « suggestion » pour matchRecommendationsToCatalog.
Map<String, dynamic> _toSuggestion(Map r) {
  final date = (r['release_date'] ?? r['first_air_date'] ?? '').toString();
  return {
    'title': (r['title'] ?? r['name'] ?? '').toString(),
    'year': date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null,
    'ids': {'tmdb': r['id']},
  };
}

/// Agrège les recommandations TMDB de plusieurs amorces (titres) dans [out],
/// en dédupliquant par id TMDB via [seen].
Future<void> _gatherRecs(dynamic tmdb, String type, List<String> names, Set<int> seen, List<Map<String, dynamic>> out) async {
  for (final name in names) {
    final hit = await tmdb.search(type, name);
    final id = hit?['id'];
    if (id is! int) continue;
    for (final r in await tmdb.recommendations(type, id)) {
      final rid = r['id'];
      if (rid is! int || !seen.add(rid)) continue;
      out.add(_toSuggestion(r));
    }
  }
}

/// Recommandations séries : seeds = séries récemment lues → TMDB tv recommandations
/// → filtrées sur le catalogue. Si aucun seed/aucune correspondance → tendances TMDB.
final seriesRecommendationsProvider = FutureProvider<List<SeriesItem>>((ref) async {
  if (ref.watch(authControllerProvider) == null) return [];
  final catalog = await ref.watch(allSeriesProvider.future);
  if (catalog.isEmpty) return [];
  final tmdb = ref.read(tmdbServiceProvider);
  // Vivier large : recommandations de TES séries vues + des titres phares de ton
  // catalogue, PLUS les tendances — tout fusionné puis filtré sur le catalogue.
  final recentNames = ref.read(prefsProvider).recent().where((e) => e.kind == MediaKind.series).take(6).map((e) => e.name).toList();
  final catalogNames = _catalogSeedNames(catalog.map((s) => (name: s.name, rating: s.rating, added: s.lastModified)));
  final seedNames = {...recentNames, ...catalogNames}.toList();

  final seen = <int>{};
  final suggestions = <Map<String, dynamic>>[];
  await _gatherRecs(tmdb, 'tv', seedNames, seen, suggestions);
  for (final r in await tmdb.trending('tv')) {
    final rid = r['id'];
    if (rid is! int || !seen.add(rid)) continue;
    suggestions.add(_toSuggestion(r));
  }
  if (suggestions.isEmpty) return [];
  final catalogMaps = catalog.map((s) => {'name': s.name, '_tmdbId': s.tmdbId, 'releaseDate': null, '__ref': s}).toList();
  return matchRecommendationsToCatalog(suggestions, catalogMaps).map((mp) => mp['__ref'] as SeriesItem).take(40).toList();
});

/// Watchlist Trakt (films « à voir ») filtrée sur le catalogue disponible.
final traktWatchlistProvider = FutureProvider<List<VodItem>>((ref) async {
  if (ref.watch(authControllerProvider) == null) return [];
  final trakt = ref.read(traktServiceProvider);
  if (!trakt.connected) return [];
  final catalog = await ref.watch(allVodProvider.future);
  if (catalog.isEmpty) return [];
  final wl = await trakt.watchlist('movies');
  if (wl.isEmpty) return [];
  final catalogMaps = catalog.map((m) => {'name': m.name, '_tmdbId': m.tmdbId, 'releaseDate': null, '__ref': m}).toList();
  return matchRecommendationsToCatalog(wl, catalogMaps).map((mp) => mp['__ref'] as VodItem).take(40).toList();
});

/// Recommandations films : seeds = films récemment lus → TMDB recommandations →
/// filtrées sur le catalogue. Si aucun seed/aucune correspondance → tendances TMDB.
final movieRecommendationsProvider = FutureProvider<List<VodItem>>((ref) async {
  final prof = ref.watch(authControllerProvider); // recrée si profil change
  if (prof == null) return [];
  final catalog = await ref.watch(allVodProvider.future);
  if (catalog.isEmpty) return [];
  final tmdb = ref.read(tmdbServiceProvider);

  // Vivier large : recommandations de TES films vus + des titres phares de ton
  // catalogue, PLUS les tendances — tout fusionné puis filtré sur le catalogue.
  final recentNames = ref.read(prefsProvider).recent().where((e) => e.kind == MediaKind.movie).take(6).map((e) => e.name).toList();
  final catalogNames = _catalogSeedNames(catalog.map((m) => (name: m.name, rating: m.rating, added: m.added)));
  final seedNames = {...recentNames, ...catalogNames}.toList();

  final seen = <int>{};
  final suggestions = <Map<String, dynamic>>[];
  await _gatherRecs(tmdb, 'movie', seedNames, seen, suggestions);
  for (final r in await tmdb.trending('movie')) {
    final rid = r['id'];
    if (rid is! int || !seen.add(rid)) continue;
    suggestions.add(_toSuggestion(r));
  }
  if (suggestions.isEmpty) return [];

  // Matche contre le catalogue (par titre nettoyé + année) et exclut le déjà-vu.
  final catalogMaps = catalog.map((m) => {'name': m.name, '_tmdbId': m.tmdbId, 'releaseDate': null, '__ref': m}).toList();
  final matched = matchRecommendationsToCatalog(suggestions, catalogMaps);
  final watchedIds = ref.read(prefsProvider).watchedMap().keys.toSet();
  return matched.map((mp) => mp['__ref'] as VodItem).where((m) => !watchedIds.contains('movie:${m.streamId}')).take(24).toList();
});
