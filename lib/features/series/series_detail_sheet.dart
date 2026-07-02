import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/logic/duration_parse.dart';
import '../../core/logic/text_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/providers.dart';
import '../../services/tmdb/tmdb_service.dart';
import '../../services/tmdb/tmdb_providers.dart';
import '../../services/downloads/download_service.dart';
import '../../services/trakt/trakt_providers.dart';
import '../auth/auth_controller.dart';
import '../player/play_launcher.dart';
import 'series_providers.dart';
import '../../l10n/app_localizations.dart';

/// Ouvre la fiche série en dialogue centré (2 colonnes).
void showSeriesDetail(BuildContext context, SeriesItem series) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: KtvColors.panel,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 940, maxHeight: 600),
        child: SeriesDetail(series: series),
      ),
    ),
  );
}

/// 2 colonnes : gauche = affiche + synopsis TMDB ; droite = saisons + épisodes.
class SeriesDetail extends ConsumerStatefulWidget {
  final SeriesItem series;
  const SeriesDetail({super.key, required this.series});
  @override
  ConsumerState<SeriesDetail> createState() => _SeriesDetailState();
}

class _SeriesDetailState extends ConsumerState<SeriesDetail> {
  String? _season;

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(seriesInfoProvider(widget.series.seriesId));
    final d = ref.watch(tmdbSearchProvider((type: 'tv', name: widget.series.name))).asData?.value;
    final poster = TmdbService.img(d?['poster_path'] as String?, size: 'w342');
    final overview = (d?['overview'] as String?)?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colonne gauche : affiche + synopsis
        SizedBox(
          width: 260,
          child: Container(
            color: KtvColors.panel2,
            padding: const EdgeInsets.all(18),
            child: ListView(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: (poster.isNotEmpty || (widget.series.cover ?? '').isNotEmpty)
                        ? CachedNetworkImage(imageUrl: poster.isNotEmpty ? poster : widget.series.cover!, fit: BoxFit.cover, errorWidget: (_, _, _) => ColoredBox(color: KtvColors.panel))
                        : ColoredBox(color: KtvColors.panel, child: Icon(Icons.grid_view_rounded, color: KtvColors.muted)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(cleanTitle(widget.series.name), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                if (widget.series.rating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Icon(Icons.star, color: KtvColors.accent2, size: 15),
                      const SizedBox(width: 4),
                      Text(widget.series.rating.toStringAsFixed(1), style: TextStyle(color: KtvColors.accent2)),
                    ]),
                  ),
                if (overview.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 10), child: Text(overview, style: TextStyle(color: KtvColors.muted, height: 1.4, fontSize: 12.5))),
                const SizedBox(height: 12),
                Builder(builder: (_) {
                  ref.watch(recentTickProvider);
                  final fav = ref.read(prefsProvider).isMediaFav('series', widget.series.seriesId);
                  return OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(prefsProvider).toggleMediaFav(kind: 'series', id: widget.series.seriesId, name: widget.series.name, cover: widget.series.cover);
                      ref.read(recentTickProvider.notifier).state++;
                      if (mounted) setState(() {});
                    },
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? KtvColors.accent : null, size: 18),
                    label: Text(fav ? L.of(context)!.actionFav : L.of(context)!.actionAddFav),
                    style: fav ? OutlinedButton.styleFrom(foregroundColor: KtvColors.accent) : null,
                  );
                }),
              ],
            ),
          ),
        ),
        // Colonne droite : saisons + épisodes
        Expanded(
          child: Stack(
            children: [
              AsyncView<Map<String, List<Episode>>>(
                value: info,
                isEmpty: (m) => m.isEmpty,
                emptyBuilder: () => Center(child: Text(L.of(context)!.emptyNoEpisode, style: TextStyle(color: KtvColors.muted))),
                data: (seasons) {
                  final keys = seasons.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
                  final season = _season ?? keys.first;
                  final eps = seasons[season] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                        child: Row(
                          children: [
                            DropdownButton<String>(
                              value: season,
                              dropdownColor: KtvColors.panel2,
                              underline: const SizedBox(),
                              items: keys.map((k) => DropdownMenuItem(value: k, child: Text(L.of(context)!.seasonN(k)))).toList(),
                              onChanged: (v) => setState(() => _season = v),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _downloadSeason(season, eps),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(L.of(context)!.dlSeasonBtn(eps.length)),
                            ),
                            TextButton.icon(
                              onPressed: () => _downloadAll(seasons),
                              icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                              label: Text(L.of(context)!.dlWholeSeries(seasons.values.fold<int>(0, (a, b) => a + b.length))),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: eps.length,
                          itemBuilder: (_, i) {
                            final ep = eps[i];
                            final watched = ref.read(prefsProvider).isWatched('series:${ep.id}');
                            return ListTile(
                              leading: CircleAvatar(backgroundColor: KtvColors.panel2, child: Text('${ep.episodeNum}', style: TextStyle(color: KtvColors.txt))),
                              title: Text(ep.title.isEmpty ? 'Épisode ${ep.episodeNum}' : ep.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Télécharger',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(Icons.download_rounded, size: 18, color: KtvColors.muted),
                                    onPressed: () => _downloadEpisode(ep, season),
                                  ),
                                  IconButton(
                                    tooltip: watched ? 'Marquer non vu' : 'Marquer comme vu',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(watched ? Icons.check_circle : Icons.check_circle_outline, size: 18, color: watched ? KtvColors.accent : KtvColors.muted),
                                    onPressed: () => _toggleEpisodeWatched(ep, season),
                                  ),
                                  Icon(Icons.play_arrow, color: KtvColors.accent2),
                                ],
                              ),
                              onTap: () => _play(ep, season, eps),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(color: Colors.black45, shape: const CircleBorder(), child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _play(Episode ep, String season, List<Episode> seasonEps) {
    final dur = parseXtreamDuration(ep.info);
    Navigator.pop(context);
    PlayLauncher.episode(context, ref, widget.series, ep, durationSec: dur, seasonEps: seasonEps);
  }

  String _epName(Episode ep, String season) =>
      '${cleanTitle(widget.series.name)} S${season.padLeft(2, '0')}E${ep.episodeNum.toString().padLeft(2, '0')}';

  void _downloadEpisode(Episode ep, String season) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    ref.read(downloadControllerProvider.notifier).enqueue(name: _epName(ep, season), url: urls.series(ep.id, ep.ext), ext: ep.ext);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Épisode ajouté aux téléchargements (Réglages)')));
  }

  void _downloadSeason(String season, List<Episode> eps) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final dl = ref.read(downloadControllerProvider.notifier);
    for (final ep in eps) {
      dl.enqueue(name: _epName(ep, season), url: urls.series(ep.id, ep.ext), ext: ep.ext);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.of(context)!.dlEnqueued(eps.length))));
  }

  /// Télécharge toute la série d'un coup (tous les épisodes de toutes les saisons).
  void _downloadAll(Map<String, List<Episode>> seasons) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final dl = ref.read(downloadControllerProvider.notifier);
    var n = 0;
    for (final entry in seasons.entries) {
      for (final ep in entry.value) {
        dl.enqueue(name: _epName(ep, entry.key), url: urls.series(ep.id, ep.ext), ext: ep.ext);
        n++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.of(context)!.dlEnqueued(n))));
  }

  Future<void> _toggleEpisodeWatched(Episode ep, String season) async {
    final prefs = ref.read(prefsProvider);
    final key = 'series:${ep.id}';
    final was = prefs.isWatched(key);
    await prefs.setWatched(key, !was);
    // Scrobble Trakt (épisode) si connecté et nouvellement vu.
    final trakt = ref.read(traktServiceProvider);
    if (!was && trakt.connected) {
      trakt.markEpisodeWatched(widget.series.name, int.tryParse(season) ?? 0, ep.episodeNum);
    }
    if (mounted) setState(() {});
  }
}
