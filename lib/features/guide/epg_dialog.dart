import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../../services/recording/recording_service.dart';
import '../player/play_launcher.dart';

String epgTime(int ts) {
  if (ts == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}';
}

String epgDuration(EpgProgram p) {
  final mins = ((p.stop - p.start) / 60).round();
  if (mins <= 0) return '';
  final h = mins ~/ 60, m = mins % 60;
  return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '$m min';
}

/// Fiche programme EPG : titre, horaires, description + actions (regarder /
/// revoir en catch-up / programmer l'enregistrement).
void showEpgProgram(BuildContext context, WidgetRef ref, LiveChannel channel, EpgProgram p) {
  final dur = epgDuration(p);
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final isPast = p.stop > 0 && p.stop <= now;
  final isFuture = p.start > now;

  void scheduleRec() {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final nowDt = DateTime.now();
    final startDt = DateTime.fromMillisecondsSinceEpoch(p.start * 1000);
    final at = startDt.isBefore(nowDt) ? nowDt : startDt.subtract(const Duration(minutes: 1)); // marge début 1 min
    final endDt = DateTime.fromMillisecondsSinceEpoch(p.stop * 1000).add(const Duration(minutes: 2)); // marge fin 2 min
    final durSec = endDt.difference(at).inSeconds.clamp(60, 6 * 3600);
    ref.read(recordingControllerProvider.notifier).schedule(
          name: '${channel.name} - ${p.title}',
          url: urls.live(channel.streamId, ext: 'ts'),
          at: at,
          durationSec: durSec,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Programmé : « ${p.title} » (${epgTime(p.start)}) — Réglages → Enregistrements')));
  }

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: KtvColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (p.isNow)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: KtvColors.rec, borderRadius: BorderRadius.circular(6)),
                    child: const Text('EN DIRECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                Expanded(child: Text(channel.name, style: TextStyle(color: KtvColors.muted, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              Text(p.title.isEmpty ? 'Programme' : p.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.schedule, size: 15, color: KtvColors.accent2),
                const SizedBox(width: 6),
                Text('${epgTime(p.start)} → ${epgTime(p.stop)}${dur.isEmpty ? '' : '  ·  $dur'}',
                    style: TextStyle(color: KtvColors.accent2, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 14),
              if (p.description.isNotEmpty)
                Flexible(child: SingleChildScrollView(child: Text(p.description, style: TextStyle(color: KtvColors.txt, height: 1.45, fontSize: 13.5))))
              else
                Text('Aucune description disponible.', style: TextStyle(color: KtvColors.muted)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isPast)
                    FilledButton.icon(
                      onPressed: () { Navigator.pop(context); PlayLauncher.timeshift(context, ref, channel, p); },
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text('Revoir (catch-up)'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () { Navigator.pop(context); PlayLauncher.live(context, ref, channel); },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Regarder'),
                    ),
                  if (!isPast)
                    FilledButton.tonalIcon(
                      onPressed: scheduleRec,
                      icon: const Icon(Icons.fiber_manual_record, size: 16, color: KtvColors.rec),
                      label: Text(isFuture ? 'Programmer' : 'Enregistrer'),
                    ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
