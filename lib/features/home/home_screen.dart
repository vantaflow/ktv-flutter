import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/widgets/media_rail.dart';
import '../../core/widgets/poster_rail.dart';
import '../auth/auth_controller.dart';
import '../player/play_launcher.dart';
import '../vod/movie_detail_sheet.dart';
import '../series/series_detail_sheet.dart';
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

    double progressOf(RecentEntry e) {
      if (e.resumeKey == null) return 0;
      final r = prefs.resume(e.resumeKey!);
      final t = (r?['t'] as num?)?.toDouble() ?? 0;
      final d = (r?['d'] as num?)?.toDouble() ?? 0;
      return d > 0 ? (t / d) : 0;
    }

    final resume = recent.where((e) => progressOf(e) > 0).toList();
    final favs = prefs
        .favChannels()
        .map((f) => RecentEntry(kind: MediaKind.live, id: '${f['id']}', name: '${f['name']}', cover: f['cover'] as String?, ext: 'ts', at: 0))
        .toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(prof?.label)),
          // Rails (chacun se masque tout seul s'il est vide).
          SliverToBoxAdapter(
            child: MediaRail(title: 'Chaînes favorites', items: favs, onTap: (e) => PlayLauncher.recent(context, ref, e)),
          ),
          SliverToBoxAdapter(
            child: MediaRail(title: 'Reprendre la lecture', items: resume, progressOf: progressOf, onTap: (e) => PlayLauncher.recent(context, ref, e)),
          ),
          SliverToBoxAdapter(
            child: MediaRail(title: 'Vu récemment', items: recent, progressOf: progressOf, onTap: (e) => PlayLauncher.recent(context, ref, e)),
          ),
          SliverToBoxAdapter(child: _recoRail()),
          SliverToBoxAdapter(child: _recoSeriesRail()),
          SliverToBoxAdapter(child: _latestVodRail()),
          SliverToBoxAdapter(child: _latestSeriesRail()),
          if (recent.isEmpty && favs.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 40), child: _loadingOrEmpty())),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _loadingOrEmpty() {
    final loading = ref.watch(latestVodProvider).isLoading || ref.watch(latestSeriesProvider).isLoading;
    if (loading) return const Center(child: CircularProgressIndicator(color: KtvColors.accent));
    return const _EmptyHome();
  }

  Widget _recoRail() {
    final recos = ref.watch(movieRecommendationsProvider).asData?.value ?? const [];
    return PosterRail(
      title: 'Recommandé pour vous',
      items: recos.map((m) => PosterRailItem(title: m.name, cover: m.cover, rating: m.rating, onTap: () => _openMovie(m))).toList(),
    );
  }

  Widget _recoSeriesRail() {
    final recos = ref.watch(seriesRecommendationsProvider).asData?.value ?? const [];
    return PosterRail(
      title: 'Séries recommandées',
      items: recos.map((s) => PosterRailItem(title: s.name, cover: s.cover, rating: s.rating, onTap: () => _openSeries(s))).toList(),
    );
  }

  Widget _latestVodRail() {
    final list = ref.watch(latestVodProvider).asData?.value ?? const [];
    return PosterRail(
      title: 'Derniers films ajoutés',
      items: list.map((m) => PosterRailItem(title: m.name, cover: m.cover, rating: m.rating, onTap: () => _openMovie(m))).toList(),
    );
  }

  Widget _latestSeriesRail() {
    final list = ref.watch(latestSeriesProvider).asData?.value ?? const [];
    return PosterRail(
      title: 'Dernières séries ajoutées',
      items: list.map((s) => PosterRailItem(title: s.name, cover: s.cover, rating: s.rating, onTap: () => _openSeries(s))).toList(),
    );
  }

  void _openMovie(VodItem m) => showMovieDetail(context, m);
  void _openSeries(SeriesItem s) => showSeriesDetail(context, s);

  Widget _header(String? label) => Padding(
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
            if (label != null) Text(label, style: const TextStyle(color: KtvColors.muted, fontSize: 12)),
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
            const Icon(Icons.play_circle_outline, color: KtvColors.muted, size: 56),
            const SizedBox(height: 16),
            const Text('Rien à reprendre pour le moment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Lance un film, une série ou une chaîne — ça apparaîtra ici.',
                style: TextStyle(color: KtvColors.muted)),
          ],
        ),
      );
}
