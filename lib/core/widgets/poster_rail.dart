import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'poster_card.dart';

class PosterRailItem {
  final String title;
  final String? cover;
  final double? rating;
  final VoidCallback onTap;
  const PosterRailItem({required this.title, this.cover, this.rating, required this.onTap});
}

/// Rangée horizontale d'affiches (films/séries) pour l'accueil.
class PosterRail extends StatelessWidget {
  final String title;
  final List<PosterRailItem> items;
  const PosterRail({super.key, required this.title, required this.items});

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
              final it = items[i];
              return PosterCard(title: it.title, imageUrl: it.cover, rating: it.rating, width: 120, onTap: it.onTap);
            },
          ),
        ),
      ],
    );
  }
}
