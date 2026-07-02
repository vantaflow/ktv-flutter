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
import '../../services/epg/epg_providers.dart';
import 'search_providers.dart';
import '../../l10n/app_localizations.dart';

/// Résultats de recherche (le champ est dans la barre supérieure du shell).
/// Affiché par-dessus le contenu dès que la requête ≥ 2 caractères.
class SearchResults extends ConsumerWidget {
  const SearchResults({super.key});

  bool _match(String name, String q) => name.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(searchQueryProvider).toLowerCase();
    if (q.length < 2) {
      return Center(child: Text(L.of(context)!.searchMin, style: TextStyle(color: KtvColors.muted)));
    }
    final movies = ref.watch(allVodProvider).asData?.value ?? const <VodItem>[];
    final series = ref.watch(allSeriesProvider).asData?.value ?? const <SeriesItem>[];
    final live = ref.watch(allLiveProvider).asData?.value ?? const <LiveChannel>[];

    final mHit = movies.where((m) => _match(m.name, q)).take(30).toList();
    final sHit = series.where((s) => _match(s.name, q)).take(30).toList();
    final cHit = live.where((c) => _match(c.name, q)).take(30).toList();

    // Recherche EPG : programmes EN COURS dont le titre correspond → afficher la chaîne.
    final epg = ref.watch(epgIndexProvider).asData?.value;
    final eHit = <_EpgHit>[];
    if (epg != null) {
      final seenCh = cHit.map((c) => c.streamId).toSet();
      for (final ch in live) {
        final (now, _) = epg.nowNext(ch);
        if (now != null && now.title.toLowerCase().contains(q) && seenCh.add(ch.streamId)) {
          eHit.add(_EpgHit(ch, now));
          if (eHit.length >= 20) break;
        }
      }
    }

    if (mHit.isEmpty && sHit.isEmpty && cHit.isEmpty && eHit.isEmpty) {
      return Center(child: Text(L.of(context)!.emptyNoResult, style: TextStyle(color: KtvColors.muted)));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      children: [
        if (eHit.isNotEmpty) ...[_section(L.of(context)!.secNow, eHit.length), _epgList(context, ref, eHit)],
        if (cHit.isNotEmpty) ...[_section(L.of(context)!.secChannels, cHit.length), _liveGrid(context, ref, cHit)],
        if (mHit.isNotEmpty) ...[_section(L.of(context)!.secMovies, mHit.length), _posterGrid(mHit.map((m) => _Item(m.name, m.cover, m.rating, () => showMovieDetail(context, m))).toList())],
        if (sHit.isNotEmpty) ...[_section(L.of(context)!.secSeries, sHit.length), _posterGrid(sHit.map((s) => _Item(s.name, s.cover, s.rating, () => showSeriesDetail(context, s))).toList())],
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

  String _time(int ts) {
    if (ts == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _epgList(BuildContext context, WidgetRef ref, List<_EpgHit> hits) => Column(
        children: [
          for (final h in hits)
            ListTile(
              leading: (h.channel.icon != null && h.channel.icon!.isNotEmpty)
                  ? Image.network(h.channel.icon!, width: 46, height: 30, fit: BoxFit.contain, errorBuilder: (_, _, _) => Icon(Icons.live_tv, color: KtvColors.muted))
                  : Icon(Icons.live_tv, color: KtvColors.muted),
              title: Text('🔴 ${h.program.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${h.channel.name}  ·  ${_time(h.program.start)} → ${_time(h.program.stop)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
              trailing: Icon(Icons.play_arrow, color: KtvColors.accent2),
              onTap: () => PlayLauncher.live(context, ref, h.channel),
            ),
        ],
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

class _EpgHit {
  final LiveChannel channel;
  final EpgProgram program;
  _EpgHit(this.channel, this.program);
}
