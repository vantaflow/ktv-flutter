import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Carte affiche réutilisable (film/série/chaîne) — image + titre + badges.
class PosterCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double? rating;
  final bool watched;
  final double progress; // 0..1
  final VoidCallback onTap;
  final double width;
  final double aspectRatio;
  final bool isFav;
  final VoidCallback? onFavToggle;
  final BoxFit fit; // contain pour les logos de chaînes (pas de crop)
  final String? nowPlaying; // programme EPG en cours (chaînes live)
  final String? remaining; // temps restant (« ⏳ 1 h 05 ») sur la barre de progression

  const PosterCard({
    super.key,
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.rating,
    this.watched = false,
    this.progress = 0,
    this.width = 150,
    this.aspectRatio = 2 / 3,
    this.isFav = false,
    this.onFavToggle,
    this.fit = BoxFit.cover,
    this.nowPlaying,
    this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: KtvColors.panel2), // fond derrière les logos « contain »
                    _image(),
                    if (rating != null && rating! > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _badge('★ ${rating!.toStringAsFixed(1)}'),
                      ),
                    if (watched && onFavToggle == null)
                      const Positioned(top: 6, right: 6, child: _WatchedDot()),
                    if (onFavToggle != null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? KtvColors.accent : Colors.white70),
                          onPressed: onFavToggle,
                        ),
                      ),
                    if (nowPlaying != null && nowPlaying!.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(7, 14, 7, 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: KtvColors.rec, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  nowPlaying!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5, height: 1.15, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (progress > 0 && remaining != null)
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 8,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
                            child: Text(remaining!, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.04, 1),
                          minHeight: 3,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation(KtvColors.accent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, height: 1.2, color: KtvColors.txt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    if (imageUrl == null || imageUrl!.isEmpty) return const _PosterFallback();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      placeholder: (_, _) => ColoredBox(color: KtvColors.panel2),
      errorWidget: (_, _, _) => const _PosterFallback(),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 11, color: KtvColors.accent2, fontWeight: FontWeight.w600)),
      );
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: KtvColors.panel2,
        child: Center(child: Icon(Icons.movie_outlined, color: KtvColors.muted, size: 32)),
      );
}

class _WatchedDot extends StatelessWidget {
  const _WatchedDot();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: KtvColors.accent, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
}
