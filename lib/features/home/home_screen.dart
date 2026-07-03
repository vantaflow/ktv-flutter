import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/platform.dart';
import '../../core/widgets/media_rail.dart';
import '../../core/widgets/poster_rail.dart';
import '../auth/auth_controller.dart';
import '../player/play_launcher.dart';
import '../vod/movie_detail_sheet.dart';
import '../series/series_detail_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'home_providers.dart';

/// Accueil : « Reprendre la lecture » + « Vu récemment » (façon streaming).
/// Se rafraîchit à chaque affichage (StatefulWidget → recharge les prefs au build).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final prof = ref.watch(authControllerProvider);
    ref.watch(recentTickProvider); // se rafraîchit après chaque lecture
    final prefs = ref.read(prefsProvider);
    final recent = prefs.recent();
    final grid = prefs.settingBool('homeGridView', false); // rangées vs grille multi-lignes

    // Persiste les rails « catalogue » dès que les données fraîches arrivent →
    // affichage instantané depuis le cache disque au prochain démarrage.
    // (Desktop uniquement : sur mobile ces providers ne sont pas activés — OOM.)
    if (kDesktop) {
      ref.listen(latestVodProvider, (_, n) { final d = n.asData?.value; if (d != null) prefs.setRailCache('latestVod', d.map(_projVod).toList()); });
      ref.listen(latestSeriesProvider, (_, n) { final d = n.asData?.value; if (d != null) prefs.setRailCache('latestSeries', d.map(_projSeries).toList()); });
      ref.listen(movieRecommendationsProvider, (_, n) { final d = n.asData?.value; if (d != null) prefs.setRailCache('recoMovies', d.map(_projVod).toList()); });
      ref.listen(seriesRecommendationsProvider, (_, n) { final d = n.asData?.value; if (d != null) prefs.setRailCache('recoSeries', d.map(_projSeries).toList()); });
      ref.listen(traktWatchlistProvider, (_, n) { final d = n.asData?.value; if (d != null) prefs.setRailCache('watchlist', d.map(_projVod).toList()); });
    }

    double progressOf(RecentEntry e) {
      if (e.resumeKey == null) return 0;
      final r = prefs.resume(e.resumeKey!);
      final t = (r?['t'] as num?)?.toDouble() ?? 0;
      final d = (r?['d'] as num?)?.toDouble() ?? 0;
      return d > 0 ? (t / d) : 0;
    }

    num? remainingOf(RecentEntry e) {
      if (e.resumeKey == null) return null;
      final r = prefs.resume(e.resumeKey!);
      final t = (r?['t'] as num?)?.toDouble() ?? 0;
      final d = (r?['d'] as num?)?.toDouble() ?? 0;
      return (d > 0 && t < d) ? (d - t) : null;
    }

    final resume = recent.where((e) => progressOf(e) > 0).toList();
    final favs = prefs
        .favChannels()
        .map((f) => RecentEntry(kind: MediaKind.live, id: '${f['id']}', name: '${f['name']}', cover: f['cover'] as String?, ext: 'ts', categoryId: f['category'] as String?, sourceId: '${f['sourceId'] ?? ''}', at: 0))
        .toList();
    final mediaFavs = prefs.mediaFavs().map((f) {
      final kind = f['kind'] == 'series' ? MediaKind.series : MediaKind.movie;
      return RecentEntry(kind: kind, id: '${f['id']}', name: '${f['name']}', cover: f['cover'] as String?, ext: '${f['ext'] ?? 'mp4'}', at: 0);
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(prof?.label, grid)),
          // Rails (chacun se masque tout seul s'il est vide ; activables dans Réglages → Accueil).
          if (prefs.settingBool('home_favs', true))
            SliverToBoxAdapter(
              child: MediaRail(title: L.of(context)!.railFavChannels, items: favs, grid: grid, onTap: (e) => PlayLauncher.recent(context, ref, e)),
            ),
          if (prefs.settingBool('home_mediafavs', true))
            SliverToBoxAdapter(
              child: MediaRail(
                title: L.of(context)!.railMediaFavs,
                items: mediaFavs,
                grid: grid,
                onTap: (e) => e.kind == MediaKind.series
                    ? showSeriesDetail(context, SeriesItem(seriesId: e.id, name: e.name, cover: e.cover, categoryId: ''))
                    : showMovieDetail(context, VodItem(streamId: e.id, name: e.name, cover: e.cover, categoryId: '', ext: e.ext)),
              ),
            ),
          if (prefs.settingBool('home_resume', true))
            SliverToBoxAdapter(
              child: MediaRail(title: L.of(context)!.railResume, items: resume, grid: grid, progressOf: progressOf, remainingOf: remainingOf, onTap: (e) => PlayLauncher.recent(context, ref, e)),
            ),
          if (prefs.settingBool('home_recent', true))
            SliverToBoxAdapter(
              child: MediaRail(title: L.of(context)!.railRecent, items: recent, grid: grid, progressOf: progressOf, remainingOf: remainingOf, onTap: (e) => PlayLauncher.recent(context, ref, e)),
            ),
          // Rangées « catalogue complet » (Derniers/Recommandé/Watchlist) : elles
          // chargent tout le catalogue (~170k) en mémoire → réservées au DESKTOP.
          // Sur mobile/TV (RAM limitée), on les masque pour éviter les crashs OOM.
          if (kDesktop) ...[
            if (prefs.settingBool('home_watchlist', true)) SliverToBoxAdapter(child: _watchlistRail(grid)),
            if (prefs.settingBool('traktRecommendationsEnabled', true)) ...[
              if (prefs.settingBool('home_recoMovies', true)) SliverToBoxAdapter(child: _recoRail(grid)),
              if (prefs.settingBool('home_recoSeries', true)) SliverToBoxAdapter(child: _recoSeriesRail(grid)),
            ],
            if (prefs.settingBool('home_latestMovies', true)) SliverToBoxAdapter(child: _latestVodRail(grid)),
            if (prefs.settingBool('home_latestSeries', true)) SliverToBoxAdapter(child: _latestSeriesRail(grid)),
          ],
          if (recent.isEmpty && favs.isEmpty && mediaFavs.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 40), child: kDesktop ? _loadingOrEmpty() : const _EmptyHome())),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _loadingOrEmpty() {
    final loading = ref.watch(latestVodProvider).isLoading || ref.watch(latestSeriesProvider).isLoading;
    if (loading) return Center(child: CircularProgressIndicator(color: KtvColors.accent));
    return const _EmptyHome();
  }

  // --- Cache disque des rails : affichage instantané puis rafraîchi ---
  static Map<String, dynamic> _projVod(VodItem m) => {'name': m.name, 'cover': m.cover, 'rating': m.rating, 'id': m.streamId, 'ext': m.ext, 'kind': 'movie'};
  static Map<String, dynamic> _projSeries(SeriesItem s) => {'name': s.name, 'cover': s.cover, 'rating': s.rating, 'id': s.seriesId, 'kind': 'series'};

  PosterRailItem _itemFromProj(Map<String, dynamic> p) {
    final rating = (p['rating'] as num?)?.toDouble();
    if (p['kind'] == 'series') {
      final s = SeriesItem(seriesId: '${p['id']}', name: '${p['name']}', cover: p['cover'] as String?, categoryId: '', rating: rating ?? 0);
      return PosterRailItem(title: s.name, cover: s.cover, rating: rating, onTap: () => _openSeries(s));
    }
    final m = VodItem(streamId: '${p['id']}', name: '${p['name']}', cover: p['cover'] as String?, categoryId: '', ext: '${p['ext'] ?? 'mp4'}', rating: rating ?? 0);
    return PosterRailItem(title: m.name, cover: m.cover, rating: rating, onTap: () => _openMovie(m));
  }

  /// Rail « catalogue » : rend les données fraîches si dispo, sinon le cache
  /// disque (affichage instantané au démarrage), puis persiste le frais.
  Widget _cachedRail<T>(String title, bool grid, String cacheKey, List<T>? live, Map<String, dynamic> Function(T) proj) {
    final prefs = ref.read(prefsProvider);
    final items = live != null ? live.map(proj).toList() : prefs.railCache(cacheKey);
    return PosterRail(title: title, grid: grid, items: items.map(_itemFromProj).toList());
  }

  Widget _watchlistRail(bool grid) =>
      _cachedRail(L.of(context)!.railWatchlist, grid, 'watchlist', ref.watch(traktWatchlistProvider).asData?.value, _projVod);
  Widget _recoRail(bool grid) =>
      _cachedRail(L.of(context)!.railRecoMovies, grid, 'recoMovies', ref.watch(movieRecommendationsProvider).asData?.value, _projVod);
  Widget _recoSeriesRail(bool grid) =>
      _cachedRail(L.of(context)!.railRecoSeries, grid, 'recoSeries', ref.watch(seriesRecommendationsProvider).asData?.value, _projSeries);
  Widget _latestVodRail(bool grid) =>
      _cachedRail(L.of(context)!.railLatestMovies, grid, 'latestVod', ref.watch(latestVodProvider).asData?.value, _projVod);
  Widget _latestSeriesRail(bool grid) =>
      _cachedRail(L.of(context)!.railLatestSeries, grid, 'latestSeries', ref.watch(latestSeriesProvider).asData?.value, _projSeries);

  void _openMovie(VodItem m) => showMovieDetail(context, m);
  void _openSeries(SeriesItem s) => showSeriesDetail(context, s);

  Widget _header(String? label, bool grid) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: KtvColors.accentGradient, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Accueil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const Spacer(),
            // Bascule d'affichage : rangées (défilement) ⇄ grille (plusieurs lignes).
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12))),
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.view_carousel_outlined, size: 16), label: Text('Rangées')),
                ButtonSegment(value: true, icon: Icon(Icons.grid_view_rounded, size: 16), label: Text('Grille')),
              ],
              selected: {grid},
              onSelectionChanged: (s) async {
                await ref.read(prefsProvider).setSetting('homeGridView', s.first);
                setState(() {});
              },
            ),
            if (label != null) ...[const SizedBox(width: 14), Text(label, style: TextStyle(color: KtvColors.muted, fontSize: 12))],
          ],
        ),
      );
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, color: KtvColors.muted, size: 56),
            const SizedBox(height: 16),
            const Text('Rien à reprendre pour le moment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Lance un film, une série ou une chaîne — ça apparaîtra ici.',
                style: TextStyle(color: KtvColors.muted)),
          ],
        ),
      );
}
