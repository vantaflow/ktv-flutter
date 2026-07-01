import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/logic/duration_parse.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_view.dart';
import '../../core/providers.dart';
import '../../services/tmdb/tmdb_service.dart';
import '../../services/tmdb/tmdb_providers.dart';
import '../player/play_launcher.dart';
import 'series_providers.dart';

/// Feuille détail d'une série : sélecteur de saison + liste d'épisodes.
class SeriesDetailSheet extends ConsumerStatefulWidget {
  final SeriesItem series;
  const SeriesDetailSheet({super.key, required this.series});
  @override
  ConsumerState<SeriesDetailSheet> createState() => _SeriesDetailSheetState();
}

class _SeriesDetailSheetState extends ConsumerState<SeriesDetailSheet> {
  String? _season;

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(seriesInfoProvider(widget.series.seriesId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (_, scroll) => Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: KtvColors.line, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text(widget.series.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          _tmdbHeader(),
          Expanded(
            child: AsyncView<Map<String, List<Episode>>>(
              value: info,
              isEmpty: (m) => m.isEmpty,
              emptyBuilder: () => const Center(child: Text('Aucun épisode', style: TextStyle(color: KtvColors.muted))),
              data: (seasons) {
                final keys = seasons.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
                final season = _season ?? keys.first;
                final eps = seasons[season] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButton<String>(
                        value: season,
                        dropdownColor: KtvColors.panel2,
                        underline: const SizedBox(),
                        items: keys.map((k) => DropdownMenuItem(value: k, child: Text('Saison $k'))).toList(),
                        onChanged: (v) => setState(() => _season = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scroll,
                        itemCount: eps.length,
                        itemBuilder: (_, i) {
                          final ep = eps[i];
                          final prefs = ref.read(prefsProvider);
                          final watched = prefs.isWatched('series:${ep.id}');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: KtvColors.panel2,
                              child: Text('${ep.episodeNum}', style: const TextStyle(color: KtvColors.txt)),
                            ),
                            title: Text(ep.title.isEmpty ? 'Épisode ${ep.episodeNum}' : ep.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: watched ? const Icon(Icons.check_circle, color: KtvColors.accent, size: 18) : const Icon(Icons.play_arrow),
                            onTap: () => _play(ep, season),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tmdbHeader() {
    final d = ref.watch(tmdbSearchProvider((type: 'tv', name: widget.series.name))).asData?.value;
    if (d == null) return const SizedBox.shrink();
    final backdrop = TmdbService.img(d['backdrop_path'] as String?, size: 'w780');
    final overview = (d['overview'] as String?)?.trim() ?? '';
    if (backdrop.isEmpty && overview.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backdrop.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: CachedNetworkImage(imageUrl: backdrop, fit: BoxFit.cover, errorWidget: (_, _, _) => const ColoredBox(color: KtvColors.panel2)),
              ),
            ),
          if (overview.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(overview, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KtvColors.muted, height: 1.35, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  void _play(Episode ep, String season) {
    final dur = parseXtreamDuration(ep.info);
    Navigator.pop(context);
    PlayLauncher.episode(context, ref, widget.series, ep, durationSec: dur);
  }
}
