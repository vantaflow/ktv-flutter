import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'poster_card.dart';

/// Rangée « à la Netflix » d'entrées rejouables (accueil). [grid] = plusieurs
/// lignes (au lieu du défilement horizontal).
class MediaRail extends StatelessWidget {
  final String title;
  final List<RecentEntry> items;
  final void Function(RecentEntry) onTap;
  final double Function(RecentEntry)? progressOf;
  final bool grid;

  const MediaRail({super.key, required this.title, required this.items, required this.onTap, this.progressOf, this.grid = false});

  Widget _card(RecentEntry e, {double width = 130}) => PosterCard(
        title: e.name,
        imageUrl: e.cover,
        width: width,
        aspectRatio: 2 / 3,
        progress: progressOf?.call(e) ?? 0,
        onTap: () => onTap(e),
      );

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: KtvColors.txt)),
        ),
        if (grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, mainAxisSpacing: 16, crossAxisSpacing: 14, childAspectRatio: 0.5),
              itemCount: items.length,
              itemBuilder: (_, i) => _card(items[i], width: double.infinity),
            ),
          )
        else
          SizedBox(
            height: 245,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _card(items[i]),
            ),
          ),
      ],
    );
  }
}
