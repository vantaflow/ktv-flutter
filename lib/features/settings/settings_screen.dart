import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs_store.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/downloads/download_service.dart';
import '../../services/recording/recording_service.dart';
import '../../services/epg/epg_providers.dart';
import '../home/home_providers.dart';
import '../auth/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prof = ref.watch(authControllerProvider);
    final prefs = ref.read(prefsProvider);
    final profiles = prefs.profiles();
    final buffer = prefs.settingStr('bufferProfile', 'balanced');

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Réglages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _section('Compte actif', [
          if (prof != null) _row('Serveur', prof.srv),
          if (prof != null) _row('Utilisateur', prof.usr),
        ]),
        const SizedBox(height: 16),
        _section('Lecture', [
          const Text('Mémoire tampon', style: TextStyle(color: KtvColors.muted, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final p in const [('low', 'Faible latence'), ('balanced', 'Équilibré'), ('stable', 'Stable')])
                ChoiceChip(
                  label: Text(p.$2),
                  selected: buffer == p.$1,
                  selectedColor: KtvColors.accent,
                  backgroundColor: KtvColors.panel2,
                  onSelected: (_) async {
                    await prefs.setSetting('bufferProfile', p.$1);
                    setState(() {});
                  },
                ),
            ],
          ),
        ]),
        const SizedBox(height: 16),
        _recordingsSection(),
        const SizedBox(height: 16),
        _downloadsSection(),
        const SizedBox(height: 16),
        _tmdbSection(prefs),
        const SizedBox(height: 16),
        _traktSection(prefs),
        const SizedBox(height: 16),
        _appSection(),
        const SizedBox(height: 16),
        _section('Profils enregistrés', [
          for (final p in profiles)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.label),
              subtitle: Text(p.srv, style: const TextStyle(color: KtvColors.muted, fontSize: 12)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (p.id == prof?.id) const Icon(Icons.check_circle, color: KtvColors.accent, size: 18),
                IconButton(icon: const Icon(Icons.delete_outline, color: KtvColors.muted), onPressed: () => ref.read(authControllerProvider.notifier).deleteProfile(p.id)),
              ]),
            ),
        ]),
        const SizedBox(height: 24),
        FilledButton.tonal(onPressed: () => ref.read(authControllerProvider.notifier).logout(), child: const Text('Se déconnecter')),
      ],
    );
  }

  Widget _tmdbSection(PrefsStore prefs) {
    return _section('Métadonnées (TMDB)', [
      const Text('Laisse vide pour utiliser le proxy KTV. Ou colle ta clé v4 TMDB (appel direct).', style: TextStyle(color: KtvColors.muted, fontSize: 12)),
      const SizedBox(height: 8),
      TextField(
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Clé TMDB v4 (optionnel)'),
        controller: TextEditingController(text: prefs.settingStr('tmdbKey')),
        onChanged: (v) => prefs.setSetting('tmdbKey', v.trim()),
      ),
    ]);
  }

  Widget _appSection() {
    return _section('Application', [
      const Text('KTV — Flutter + media_kit · v0.1.2', style: TextStyle(color: KtvColors.muted, fontSize: 13)),
      const SizedBox(height: 10),
      FilledButton.tonalIcon(
        onPressed: () {
          // Recharge catalogues + EPG.
          ref.invalidate(allVodProvider);
          ref.invalidate(allSeriesProvider);
          ref.invalidate(latestVodProvider);
          ref.invalidate(latestSeriesProvider);
          ref.invalidate(epgIndexProvider);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catalogue et EPG rafraîchis')));
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Rafraîchir le catalogue et l\'EPG'),
      ),
    ]);
  }

  String _hhmm(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _recordingsSection() {
    final recs = ref.watch(recordingControllerProvider);
    final rec = ref.watch(recordingControllerProvider.notifier);
    return _section('Enregistrements', [
      if (recs.isEmpty)
        const Text('Aucun enregistrement. Bouton ● sur une chaîne Live, ou ⏱ pour programmer.', style: TextStyle(color: KtvColors.muted, fontSize: 13))
      else
        for (final r in recs.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(
                switch (r.status) {
                  RecStatus.scheduled => Icons.schedule,
                  RecStatus.recording => Icons.fiber_manual_record,
                  RecStatus.done => Icons.check_circle,
                  RecStatus.error => Icons.error,
                },
                size: 16,
                color: switch (r.status) {
                  RecStatus.recording => KtvColors.rec,
                  RecStatus.done => KtvColors.accent,
                  RecStatus.scheduled => KtvColors.accent2,
                  RecStatus.error => KtvColors.muted,
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    if (r.status == RecStatus.scheduled && r.startAt != null)
                      Text('Programmé — commence à ${_hhmm(r.startAt!)}', style: const TextStyle(color: KtvColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              if (r.status == RecStatus.recording)
                TextButton(onPressed: () => rec.stop(), child: const Text('Arrêter'))
              else if (r.status == RecStatus.scheduled)
                TextButton(onPressed: () => rec.cancelScheduled(r.id), child: const Text('Annuler')),
            ]),
          ),
    ]);
  }

  Widget _downloadsSection() {
    final jobs = ref.watch(downloadControllerProvider);
    return _section('Téléchargements', [
      if (jobs.isEmpty)
        const Text('Aucun téléchargement.', style: TextStyle(color: KtvColors.muted, fontSize: 13))
      else
        for (final j in jobs.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: j.status == DownloadStatus.done ? 1 : (j.progress == 0 ? null : j.progress),
                        minHeight: 4,
                        backgroundColor: KtvColors.panel2,
                        valueColor: AlwaysStoppedAnimation(
                          j.status == DownloadStatus.error ? KtvColors.rec : KtvColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  switch (j.status) {
                    DownloadStatus.done => '✓',
                    DownloadStatus.error => 'échec',
                    DownloadStatus.canceled => 'annulé',
                    DownloadStatus.downloading => '${(j.progress * 100).round()}%',
                    DownloadStatus.queued => 'en file',
                  },
                  style: const TextStyle(color: KtvColors.muted, fontSize: 12),
                ),
                if (j.status == DownloadStatus.downloading)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: KtvColors.muted),
                    onPressed: () => ref.read(downloadControllerProvider.notifier).cancelCurrent(),
                  ),
              ],
            ),
          ),
    ]);
  }

  Widget _traktSection(PrefsStore prefs) {
    final connected = prefs.traktConnected;
    return _section('Synchronisation Trakt', [
      const Text('Crée une appli sur trakt.tv/oauth/applications, colle Client ID + Secret.', style: TextStyle(color: KtvColors.muted, fontSize: 12)),
      const SizedBox(height: 8),
      TextField(
        decoration: const InputDecoration(hintText: 'Client ID'),
        controller: TextEditingController(text: prefs.settingStr('traktClientId')),
        onChanged: (v) => prefs.setSetting('traktClientId', v.trim()),
      ),
      const SizedBox(height: 8),
      TextField(
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Client Secret'),
        controller: TextEditingController(text: prefs.settingStr('traktSecret')),
        onChanged: (v) => prefs.setSetting('traktSecret', v.trim()),
      ),
      const SizedBox(height: 10),
      if (connected)
        FilledButton.tonalIcon(
          onPressed: () async {
            await ref.read(traktServiceProvider).disconnect();
            setState(() {});
          },
          icon: const Icon(Icons.link_off),
          label: const Text('✓ Connecté — Déconnecter'),
        )
      else
        FilledButton.icon(onPressed: _connectTrakt, icon: const Icon(Icons.link), label: const Text('Connecter (code)')),
    ]);
  }

  Future<void> _connectTrakt() async {
    final trakt = ref.read(traktServiceProvider);
    if (ref.read(prefsProvider).settingStr('traktClientId').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renseigne d\'abord le Client ID.')));
      return;
    }
    Map<String, dynamic> code;
    try {
      code = await trakt.requestDeviceCode();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la demande de code Trakt.')));
      return;
    }
    final userCode = code['user_code']?.toString() ?? '';
    final url = code['verification_url']?.toString() ?? 'trakt.tv/activate';
    final deviceCode = code['device_code']?.toString() ?? '';
    final interval = (code['interval'] as num?)?.toInt() ?? 5;
    Timer? poll;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dctx) {
        poll = Timer.periodic(Duration(seconds: interval + 1), (t) async {
          final ok = await trakt.pollDeviceToken(deviceCode);
          if (ok) {
            t.cancel();
            if (dctx.mounted) Navigator.pop(dctx);
            if (mounted) setState(() {});
          }
        });
        return AlertDialog(
          backgroundColor: KtvColors.panel,
          title: const Text('Connexion Trakt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Va sur :', style: TextStyle(color: KtvColors.muted)),
              SelectableText(url, style: const TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('et saisis le code :', style: TextStyle(color: KtvColors.muted)),
              SelectableText(userCode, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3)),
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: KtvColors.accent),
            ],
          ),
        );
      },
    ).then((_) => poll?.cancel());
  }

  Widget _section(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: KtvColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: KtvColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: KtvColors.accent2)),
          const SizedBox(height: 8),
          ...children,
        ]),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 120, child: Text(k, style: const TextStyle(color: KtvColors.muted))),
          Expanded(child: Text(v, overflow: TextOverflow.ellipsis)),
        ]),
      );
}
