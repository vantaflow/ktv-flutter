import 'dart:async';
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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = v.trim();
    });
  }

  bool _match(String name, String q) => name.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(searchQueryProvider).toLowerCase();
    final movies = (ref.watch(allVodProvider).asData?.value ?? const <VodItem>[]);
    final series = (ref.watch(allSeriesProvider).asData?.value ?? const <SeriesItem>[]);
    final live = (ref.watch(allLiveProvider).asData?.value ?? const <LiveChannel>[]);

    final mHit = q.length < 2 ? <VodItem>[] : movies.where((m) => _match(m.name, q)).take(30).toList();
    final sHit = q.length < 2 ? <SeriesItem>[] : series.where((s) => _match(s.name, q)).take(30).toList();
    final cHit = q.length < 2 ? <LiveChannel>[] : live.where((c) => _match(c.name, q)).take(30).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Rechercher chaînes, films, séries…',
                prefixIcon: Icon(Icons.search, color: KtvColors.muted),
              ),
            ),
          ),
          Expanded(
            child: q.length < 2
                ? const Center(child: Text('Tape au moins 2 caractères', style: TextStyle(color: KtvColors.muted)))
                : (mHit.isEmpty && sHit.isEmpty && cHit.isEmpty)
                    ? const Center(child: Text('Aucun résultat', style: TextStyle(color: KtvColors.muted)))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          _section('📺 Chaînes', cHit.length),
                          if (cHit.isNotEmpty) _liveGrid(cHit),
                          _section('🎬 Films', mHit.length),
                          if (mHit.isNotEmpty) _posterGrid(mHit.map((m) => _Item(m.name, m.cover, m.rating, () => _openMovie(m))).toList()),
                          _section('🎞️ Séries', sHit.length),
                          if (sHit.isNotEmpty) _posterGrid(sHit.map((s) => _Item(s.name, s.cover, s.rating, () => _openSeries(s))).toList()),
                        ],
                      ),
          ),
        ],
      ),
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

  Widget _liveGrid(List<LiveChannel> ch) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 210, childAspectRatio: 0.78, crossAxisSpacing: 14, mainAxisSpacing: 18),
        itemCount: ch.length,
        itemBuilder: (_, i) => LiveChannelCard(channel: ch[i], onTap: () => PlayLauncher.live(context, ref, ch[i])),
      );

  void _openMovie(VodItem m) => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: KtvColors.panel,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => MovieDetailSheet(movie: m));

  void _openSeries(SeriesItem s) => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: KtvColors.panel,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
        builder: (_) => SeriesDetailSheet(series: s));
}

class _Item {
  final String name;
  final String? cover;
  final double? rating;
  final VoidCallback onTap;
  _Item(this.name, this.cover, this.rating, this.onTap);
}
