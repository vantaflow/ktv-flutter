import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/poster_card.dart';
import '../home/home_providers.dart';
import '../live/live_channel_card.dart';
import '../vod/movie_detail_sheet.dart';
import '../series/series_detail_sheet.dart';
import '../player/play_launcher.dart';
import 'search_providers.dart';

/// Résultats de recherche (le champ est dans la barre supérieure du shell).
/// Affiché par-dessus le contenu dès que la requête ≥ 2 caractères.
class SearchResults extends ConsumerWidget {
  const SearchResults({super.key});

  bool _match(String name, String q) => name.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(searchQueryProvider).toLowerCase();
    if (q.length < 2) {
      return const Center(child: Text('Tape au moins 2 caractères', style: TextStyle(color: KtvColors.muted)));
    }
    final movies = ref.watch(allVodProvider).asData?.value ?? const <VodItem>[];
    final series = ref.watch(allSeriesProvider).asData?.value ?? const <SeriesItem>[];
    final live = ref.watch(allLiveProvider).asData?.value ?? const <LiveChannel>[];

    final mHit = movies.where((m) => _match(m.name, q)).take(30).toList();
    final sHit = series.where((s) => _match(s.name, q)).take(30).toList();
    final cHit = live.where((c) => _match(c.name, q)).take(30).toList();

    if (mHit.isEmpty && sHit.isEmpty && cHit.isEmpty) {
      return const Center(child: Text('Aucun résultat', style: TextStyle(color: KtvColors.muted)));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      children: [
        if (cHit.isNotEmpty) ...[_section('📺 Chaînes', cHit.length), _liveGrid(context, ref, cHit)],
        if (mHit.isNotEmpty) ...[_section('🎬 Films', mHit.length), _posterGrid(mHit.map((m) => _Item(m.name, m.cover, m.rating, () => showMovieDetail(context, m))).toList())],
        if (sHit.isNotEmpty) ...[_section('🎞️ Séries', sHit.length), _posterGrid(sHit.map((s) => _Item(s.name, s.cover, s.rating, () => showSeriesDetail(context, s))).toList())],
      ],
    );
  }

  Widget _section(String title, int n) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Text('$title ($n)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );

  Widget _posterGrid(List<_Item> items) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: 0.52, crossAxisSpacing: 12, mainAxisSpacing: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => PosterCard(title: items[i].name, imageUrl: items[i].cover, rating: items[i].rating, onTap: items[i].onTap),
      );

  Widget _liveGrid(BuildContext context, WidgetRef ref, List<LiveChannel> ch) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 210, childAspectRatio: 0.78, crossAxisSpacing: 14, mainAxisSpacing: 18),
        itemCount: ch.length,
        itemBuilder: (_, i) => LiveChannelCard(channel: ch[i], onTap: () => PlayLauncher.live(context, ref, ch[i])),
      );
}

class _Item {
  final String name;
  final String? cover;
  final double? rating;
  final VoidCallback onTap;
  _Item(this.name, this.cover, this.rating, this.onTap);
}
