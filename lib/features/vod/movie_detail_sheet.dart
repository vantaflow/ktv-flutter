import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/logic/text_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../services/tmdb/tmdb_service.dart';
import '../../services/tmdb/tmdb_providers.dart';
import '../../services/downloads/download_service.dart';
import '../auth/auth_controller.dart';
import '../player/play_launcher.dart';

/// Ouvre la fiche film en dialogue centré (2 colonnes).
void showMovieDetail(BuildContext context, VodItem movie) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: KtvColors.panel,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 560),
        child: MovieDetail(movie: movie),
      ),
    ),
  );
}

/// Fiche film 2 colonnes : à gauche l'affiche + actions, à droite backdrop + infos + casting.
class MovieDetail extends ConsumerWidget {
  final VodItem movie;
  const MovieDetail({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tmdb = ref.watch(tmdbSearchProvider((type: 'movie', name: movie.name)));
    final d = tmdb.asData?.value;
    final backdrop = TmdbService.img(d?['backdrop_path'] as String?, size: 'w780');
    final poster = TmdbService.img(d?['poster_path'] as String?, size: 'w342');
    final overview = (d?['overview'] as String?)?.trim() ?? '';
    final rating = (d?['vote_average'] as num?)?.toDouble() ?? movie.rating;
    final year = yearOf(movie.name);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colonne gauche : affiche + actions
        SizedBox(
          width: 240,
          child: Container(
            color: KtvColors.panel2,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (poster.isNotEmpty || (movie.cover ?? '').isNotEmpty)
                        ? CachedNetworkImage(imageUrl: poster.isNotEmpty ? poster : movie.cover!, fit: BoxFit.cover, errorWidget: (_, _, _) => const ColoredBox(color: KtvColors.panel))
                        : const ColoredBox(color: KtvColors.panel, child: Icon(Icons.movie_outlined, color: KtvColors.muted)),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    PlayLauncher.movie(context, ref, movie);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Lire'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final urls = ref.read(xtreamUrlsProvider);
                    if (urls == null) return;
                    ref.read(downloadControllerProvider.notifier).enqueue(name: cleanTitle(movie.name), url: urls.movie(movie.streamId, movie.ext), ext: movie.ext);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargement ajouté (Réglages → Téléchargements)')));
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger'),
                ),
              ],
            ),
          ),
        ),
        // Colonne droite : backdrop + titre + synopsis + casting
        Expanded(
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 8,
                    child: backdrop.isNotEmpty
                        ? CachedNetworkImage(imageUrl: backdrop, fit: BoxFit.cover, errorWidget: (_, _, _) => const ColoredBox(color: KtvColors.panel2))
                        : const ColoredBox(color: KtvColors.panel2),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cleanTitle(movie.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(children: [
                          if (rating > 0) ...[
                            const Icon(Icons.star, color: KtvColors.accent2, size: 16),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1), style: const TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 14),
                          ],
                          if (year.isNotEmpty) Text(year, style: const TextStyle(color: KtvColors.muted)),
                        ]),
                        const SizedBox(height: 14),
                        if (tmdb.isLoading) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: KtvColors.accent))),
                        if (overview.isNotEmpty)
                          Text(overview, style: const TextStyle(color: KtvColors.txt, height: 1.45))
                        else if (!tmdb.isLoading)
                          const Text('Aucune description disponible.', style: TextStyle(color: KtvColors.muted)),
                        if (d?['id'] is int) _CastRow(id: d!['id'] as int),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(top: 8, right: 8, child: _closeBtn(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _closeBtn(BuildContext context) => Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      );
}

class _CastRow extends ConsumerWidget {
  final int id;
  const _CastRow({required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final det = ref.watch(tmdbDetailsProvider((type: 'movie', id: id))).asData?.value;
    final cast = (det?['credits']?['cast'] as List?)?.whereType<Map>().take(12).toList() ?? const [];
    if (cast.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Casting', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = cast[i];
                final photo = TmdbService.img(c['profile_path'] as String?, size: 'w185');
                return SizedBox(
                  width: 70,
                  child: Column(children: [
                    CircleAvatar(radius: 30, backgroundColor: KtvColors.panel2, backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null, child: photo.isEmpty ? const Icon(Icons.person, color: KtvColors.muted) : null),
                    const SizedBox(height: 6),
                    Text('${c['name'] ?? ''}', maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5)),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
