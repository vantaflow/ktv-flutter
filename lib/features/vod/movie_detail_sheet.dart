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

/// Fiche film : backdrop + synopsis + note (TMDB), bouton Lire — façon KTV.
class MovieDetailSheet extends ConsumerWidget {
  final VodItem movie;
  const MovieDetailSheet({super.key, required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tmdb = ref.watch(tmdbSearchProvider((type: 'movie', name: movie.name)));
    final d = tmdb.asData?.value;
    final backdrop = TmdbService.img(d?['backdrop_path'] as String?, size: 'w780');
    final poster = TmdbService.img(d?['poster_path'] as String?, size: 'w342');
    final overview = (d?['overview'] as String?)?.trim() ?? '';
    final rating = (d?['vote_average'] as num?)?.toDouble() ?? movie.rating;
    final year = yearOf(movie.name);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: backdrop.isNotEmpty
                    ? CachedNetworkImage(imageUrl: backdrop, fit: BoxFit.cover, errorWidget: (_, _, _) => const ColoredBox(color: KtvColors.panel2))
                    : const ColoredBox(color: KtvColors.panel2),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, KtvColors.panel]),
                  ),
                ),
              ),
              Positioned(top: 8, right: 8, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (poster.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: poster, width: 90, fit: BoxFit.cover, errorWidget: (_, _, _) => const SizedBox()),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cleanTitle(movie.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(children: [
                            if (rating > 0) ...[
                              const Icon(Icons.star, color: KtvColors.accent2, size: 16),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                            ],
                            if (year.isNotEmpty) Text(year, style: const TextStyle(color: KtvColors.muted)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                PlayLauncher.movie(context, ref, movie);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Lire'),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              tooltip: 'Télécharger',
                              icon: const Icon(Icons.download_rounded),
                              onPressed: () {
                                final urls = ref.read(xtreamUrlsProvider);
                                if (urls == null) return;
                                ref.read(downloadControllerProvider.notifier).enqueue(
                                      name: cleanTitle(movie.name),
                                      url: urls.movie(movie.streamId, movie.ext),
                                      ext: movie.ext,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Téléchargement ajouté (Réglages → Téléchargements)')),
                                );
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (tmdb.isLoading) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: KtvColors.accent))),
                if (overview.isNotEmpty)
                  Text(overview, style: const TextStyle(color: KtvColors.txt, height: 1.4))
                else if (!tmdb.isLoading)
                  const Text('Aucune description disponible.', style: TextStyle(color: KtvColors.muted)),
                if (d?['id'] is int) _CastRow(id: d!['id'] as int),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rangée de casting (photos + noms) via TMDB credits.
class _CastRow extends ConsumerWidget {
  final int id;
  const _CastRow({required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final det = ref.watch(tmdbDetailsProvider((type: 'movie', id: id))).asData?.value;
    final cast = (det?['credits']?['cast'] as List?)?.whereType<Map>().take(12).toList() ?? const [];
    if (cast.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Casting', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = cast[i];
                final photo = TmdbService.img(c['profile_path'] as String?, size: 'w185');
                return SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: KtvColors.panel2,
                        backgroundImage: photo.isNotEmpty ? CachedNetworkImageProvider(photo) : null,
                        child: photo.isEmpty ? const Icon(Icons.person, color: KtvColors.muted) : null,
                      ),
                      const SizedBox(height: 6),
                      Text('${c['name'] ?? ''}', maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
