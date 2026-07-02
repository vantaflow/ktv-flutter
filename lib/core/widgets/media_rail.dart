import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../../services/epg/epg_providers.dart';
import 'poster_card.dart';

/// Carte d'une chaîne live dans un rail : logo « contain » + programme EPG en
/// cours (résolu par nom via l'index XMLTV) affiché dans l'espace du letterbox.
class _LiveRailCard extends ConsumerWidget {
  final RecentEntry entry;
  final double width;
  final VoidCallback onTap;
  const _LiveRailCard({required this.entry, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(epgIndexProvider).asData?.value;
    final ch = LiveChannel(streamId: entry.id, name: entry.name, icon: entry.cover, categoryId: entry.categoryId ?? '');
    final (now, _) = index?.nowNext(ch) ?? (null, null);
    return PosterCard(
      title: entry.name,
      imageUrl: entry.cover,
      width: width,
      aspectRatio: 2 / 3,
      fit: BoxFit.contain,
      nowPlaying: now?.title,
      onTap: onTap,
    );
  }
}

/// Rangée « à la Netflix » d'entrées rejouables (accueil). [grid] = plusieurs
/// lignes (au lieu du défilement horizontal).
class MediaRail extends StatelessWidget {
  final String title;
  final List<RecentEntry> items;
  final void Function(RecentEntry) onTap;
  final double Function(RecentEntry)? progressOf;
  final bool grid;

  const MediaRail({super.key, required this.title, required this.items, required this.onTap, this.progressOf, this.grid = false});

  Widget _card(RecentEntry e, {double width = 130}) {
    // Chaînes live : logo tel quel (contain) + programme EPG en cours dans l'espace.
    if (e.kind == MediaKind.live) {
      return _LiveRailCard(entry: e, width: width, onTap: () => onTap(e));
    }
    return PosterCard(
      title: e.name,
      imageUrl: e.cover,
      width: width,
      aspectRatio: 2 / 3,
      progress: progressOf?.call(e) ?? 0,
      onTap: () => onTap(e),
    );
  }

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
