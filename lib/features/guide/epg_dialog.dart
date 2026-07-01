import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

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

/// Fiche programme EPG : titre, horaires début → fin, durée, description.
void showEpgProgram(BuildContext context, String channelName, EpgProgram p) {
  final dur = epgDuration(p);
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: KtvColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                Expanded(child: Text(channelName, style: const TextStyle(color: KtvColors.muted, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              Text(p.title.isEmpty ? 'Programme' : p.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.schedule, size: 15, color: KtvColors.accent2),
                const SizedBox(width: 6),
                Text('${epgTime(p.start)} → ${epgTime(p.stop)}${dur.isEmpty ? '' : '  ·  $dur'}',
                    style: const TextStyle(color: KtvColors.accent2, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 14),
              if (p.description.isNotEmpty)
                Flexible(child: SingleChildScrollView(child: Text(p.description, style: const TextStyle(color: KtvColors.txt, height: 1.45, fontSize: 13.5))))
              else
                const Text('Aucune description disponible.', style: TextStyle(color: KtvColors.muted)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
