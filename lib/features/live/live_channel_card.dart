import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tv_focusable.dart';
import '../auth/auth_controller.dart';
import '../../services/recording/recording_service.dart';
import '../../services/epg/epg_providers.dart';
import '../guide/epg_dialog.dart';

/// Carte d'une chaîne live : logo + nom + programme EN COURS (EPG now/next).
class LiveChannelCard extends ConsumerWidget {
  final LiveChannel channel;
  final VoidCallback onTap;
  const LiveChannelCard({super.key, required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(prefsProvider);
    final index = ref.watch(epgIndexProvider).asData?.value;
    final (now, next) = index?.nowNext(channel) ?? (null, null);
    final recording = ref.watch(recordingControllerProvider).any((r) => r.status == RecStatus.recording);

    return TvFocusable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (channel.icon != null && channel.icon!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: channel.icon!,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => ColoredBox(color: KtvColors.panel2),
                      errorWidget: (_, _, _) => const _LiveFallback(),
                    )
                  else
                    const _LiveFallback(),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(prefs.isFav(channel.streamId) ? Icons.favorite : Icons.favorite_border,
                          color: prefs.isFav(channel.streamId) ? KtvColors.accent : Colors.white70),
                      onPressed: () async {
                        await prefs.toggleFav(id: channel.streamId, name: channel.name, cover: channel.icon, category: channel.categoryId);
                        ref.read(recentTickProvider.notifier).state++;
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                  if (kDesktop) Positioned(
                    top: 2,
                    left: 2,
                    child: IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: recording ? 'Arrêter l\'enregistrement' : 'Enregistrer',
                      icon: Icon(recording ? Icons.stop_circle : Icons.fiber_manual_record, color: KtvColors.rec),
                      onPressed: () async {
                        final rec = ref.read(recordingControllerProvider.notifier);
                        if (recording) {
                          await rec.stop();
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement arrêté')));
                          return;
                        }
                        final urls = ref.read(xtreamUrlsProvider);
                        if (urls == null) return;
                        final err = await rec.start(name: channel.name, url: urls.live(channel.streamId, ext: 'ts'));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(err ?? 'Enregistrement démarré : ${channel.name} · la lecture reste possible (Réglages)'),
                          ));
                        }
                      },
                    ),
                  ),
                  if (now != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ProgressBar(now),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (now != null)
            InkWell(
              onTap: () => showEpgProgram(context, ref, channel, now),
              child: Text('🔴 ${now.title}  ·  jusqu\'à ${epgTime(now.stop)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: KtvColors.accent2)),
            ),
          if (next != null)
            Text('Puis ${epgTime(next.start)} · ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: KtvColors.muted)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final EpgProgram p;
  const _ProgressBar(this.p);
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final total = (p.stop - p.start);
    final done = (now - p.start);
    final v = (total > 0) ? (done / total).clamp(0.0, 1.0) : 0.0;
    if (v <= 0) return const SizedBox.shrink();
    return LinearProgressIndicator(
      value: v,
      minHeight: 3,
      backgroundColor: Colors.black45,
      valueColor: AlwaysStoppedAnimation(KtvColors.accent),
    );
  }
}

class _LiveFallback extends StatelessWidget {
  const _LiveFallback();
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: KtvColors.panel2, child: Center(child: Icon(Icons.live_tv, color: KtvColors.muted, size: 30)));
}
