import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'poster_card.dart';

/// Rangée horizontale « à la Netflix » d'entrées rejouables (accueil).
class MediaRail extends StatelessWidget {
  final String title;
  final List<RecentEntry> items;
  final void Function(RecentEntry) onTap;
  final double Function(RecentEntry)? progressOf;

  const MediaRail({super.key, required this.title, required this.items, required this.onTap, this.progressOf});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: KtvColors.txt)),
        ),
        SizedBox(
          height: 245,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final e = items[i];
              // Taille UNIFORME pour toutes les entrées (films/séries/chaînes).
              return PosterCard(
                title: e.name,
                imageUrl: e.cover,
                width: 130,
                aspectRatio: 2 / 3,
                progress: progressOf?.call(e) ?? 0,
                onTap: () => onTap(e),
              );
            },
          ),
        ),
      ],
    );
  }
}
