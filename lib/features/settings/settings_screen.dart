import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs_store.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/downloads/download_service.dart';
import '../../services/recording/recording_service.dart';
import '../../services/epg/epg_providers.dart';
import '../home/home_providers.dart';
import '../auth/auth_controller.dart';

/// Section sélectionnée dans les Réglages (layout 2 colonnes façon ancienne KTV).
final _settingsTabProvider = StateProvider<int>((ref) => 0);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _tabs = [
    (icon: Icons.person_rounded, label: 'Compte & abonnement'),
    (icon: Icons.play_circle_outline, label: 'Lecture & tampon'),
    (icon: Icons.event_note_rounded, label: 'EPG externe'),
    (icon: Icons.movie_filter_rounded, label: 'Catalogue'),
    (icon: Icons.theaters_rounded, label: 'Enrichissement TMDB'),
    (icon: Icons.sync_rounded, label: 'Synchronisation Trakt'),
    (icon: Icons.autorenew_rounded, label: 'Mise à jour auto'),
    (icon: Icons.fiber_manual_record, label: 'Enregistrements'),
    (icon: Icons.download_rounded, label: 'Téléchargements'),
    (icon: Icons.switch_account_rounded, label: 'Profils'),
    (icon: Icons.info_outline_rounded, label: 'Application'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_settingsTabProvider);
    final prefs = ref.read(prefsProvider);
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne de navigation des sections.
          SizedBox(
            width: 230,
            child: Container(
              color: KtvColors.panel,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, 14),
                    child: Text('Réglages', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  for (var i = 0; i < _tabs.length; i++)
                    _NavTab(icon: _tabs[i].icon, label: _tabs[i].label, active: i == tab, onTap: () => ref.read(_settingsTabProvider.notifier).state = i),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: KtvColors.line),
          // Contenu de la section.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(_tabs[tab].label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                ...switch (tab) {
                  0 => _account(),
                  1 => _playback(prefs),
                  2 => _epg(),
                  3 => _catalog(),
                  4 => _tmdb(prefs),
                  5 => _trakt(prefs),
                  6 => _autoRefresh(prefs),
                  7 => _recordings(),
                  8 => _downloads(),
                  9 => _profiles(),
                  _ => _app(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 👤 Compte & abonnement ---
  List<Widget> _account() {
    final info = ref.watch(userInfoProvider);
    final prof = ref.watch(authControllerProvider);
    return [
      info.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: KtvColors.accent))),
        error: (_, _) => const Text('Impossible de récupérer les infos d\'abonnement.', style: TextStyle(color: KtvColors.muted)),
        data: (ui) {
          if (ui == null) return const Text('Non connecté.', style: TextStyle(color: KtvColors.muted));
          return _card([
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _cell('Statut', ui.status.isEmpty ? '—' : ui.status, ok: ui.status.toLowerCase() == 'active'),
                _cell('Expiration', _date(ui.expDate, ifEmpty: 'Illimité')),
                _cell('Connexions', '${ui.activeCons} / ${ui.maxCons}'),
                _cell('Essai', ui.isTrial ? 'Oui' : 'Non'),
                _cell('Utilisateur', prof?.usr ?? '—'),
                _cell('Serveur', prof?.srv ?? '—'),
                _cell('Créé le', _date(ui.createdAt, ifEmpty: '—')),
                if (ui.timezone.isNotEmpty) _cell('Fuseau', ui.timezone),
                if (ui.allowedFormats.isNotEmpty) _cell('Formats', ui.allowedFormats.join(', ')),
              ],
            ),
            if (ui.message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(ui.message, style: const TextStyle(color: KtvColors.accent2, fontSize: 12.5)),
            ],
          ]);
        },
      ),
    ];
  }

  // --- ▶️ Lecture & tampon ---
  List<Widget> _playback(PrefsStore prefs) {
    final buffer = prefs.settingStr('bufferProfile', 'balanced');
    return [
      _card([
        const Text('« Faible latence » = plus proche du direct. « Stable » = gros tampon, moins de coupures.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final p in const [('low', 'Faible latence'), ('balanced', 'Équilibré (défaut)'), ('stable', 'Stable (gros tampon)')])
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
        ]),
        const SizedBox(height: 8),
        const Text('Appliqué au prochain lancement de lecture (propriété mpv cache-secs).', style: TextStyle(color: KtvColors.muted, fontSize: 11.5)),
      ]),
    ];
  }

  // --- 🗓️ EPG externe ---
  List<Widget> _epg() {
    final epg = ref.watch(epgIndexProvider);
    final status = epg.when(
      loading: () => 'chargement…',
      error: (_, _) => 'indisponible',
      data: (idx) => idx.byId.isEmpty ? 'aucune donnée' : 'activé · ${idx.byId.length} chaînes',
    );
    return [
      _card([
        const Text('Guide (XMLTV) du fournisseur, utilisé car get_short_epg est bloqué (403). Cache 6 h.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        _line('État', status),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () {
            ref.invalidate(epgIndexProvider);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EPG en cours de rechargement…')));
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Rafraîchir l\'EPG'),
        ),
      ]),
    ];
  }

  // --- 🎬 Catalogue ---
  List<Widget> _catalog() {
    return [
      _card([
        const Text('Recharge films & séries depuis le fournisseur (après ajout de nouveaux contenus).', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.tonalIcon(onPressed: () { ref.invalidate(allVodProvider); ref.invalidate(latestVodProvider); _toast('Films rafraîchis'); }, icon: const Icon(Icons.movie_rounded), label: const Text('Rafraîchir les films')),
          FilledButton.tonalIcon(onPressed: () { ref.invalidate(allSeriesProvider); ref.invalidate(latestSeriesProvider); _toast('Séries rafraîchies'); }, icon: const Icon(Icons.grid_view_rounded), label: const Text('Rafraîchir les séries')),
          FilledButton.icon(onPressed: () { ref.read(autoRefreshControllerProvider.notifier).refreshNow(); _toast('Catalogue et EPG rafraîchis'); }, icon: const Icon(Icons.refresh), label: const Text('Tout rafraîchir')),
        ]),
      ]),
    ];
  }

  // --- 🎬 Enrichissement TMDB ---
  List<Widget> _tmdb(PrefsStore prefs) {
    final enabled = prefs.settingBool('tmdbEnabled', true);
    final lang = prefs.settingStr('tmdbLang', 'fr-FR');
    return [
      _card([
        const Text('Affiches, notes, synopsis et casting pour les films & séries.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: const Text('Activer TMDB'),
          value: enabled,
          onChanged: (v) async { await prefs.setSetting('tmdbEnabled', v); setState(() {}); },
        ),
        Row(children: [
          const SizedBox(width: 4),
          const Text('Langue des métadonnées', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
          const Spacer(),
          DropdownButton<String>(
            value: lang,
            dropdownColor: KtvColors.panel2,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'fr-FR', child: Text('Français')),
              DropdownMenuItem(value: 'en-US', child: Text('English')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
            onChanged: (v) async { if (v != null) { await prefs.setSetting('tmdbLang', v); setState(() {}); } },
          ),
        ]),
        const SizedBox(height: 10),
        const Text('Clé v4 perso (optionnel — sinon proxy KTV) :', style: TextStyle(color: KtvColors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Clé TMDB v4 (optionnel)'),
          controller: TextEditingController(text: prefs.settingStr('tmdbKey')),
          onChanged: (v) => prefs.setSetting('tmdbKey', v.trim()),
        ),
      ]),
    ];
  }

  // --- 🅣 Synchronisation Trakt ---
  List<Widget> _trakt(PrefsStore prefs) {
    final connected = prefs.traktConnected;
    return [
      _card([
        const Text('Crée une appli sur trakt.tv/oauth/applications, colle Client ID + Secret.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(hintText: 'Client ID'), controller: TextEditingController(text: prefs.settingStr('traktClientId')), onChanged: (v) => prefs.setSetting('traktClientId', v.trim())),
        const SizedBox(height: 8),
        TextField(obscureText: true, decoration: const InputDecoration(hintText: 'Client Secret'), controller: TextEditingController(text: prefs.settingStr('traktSecret')), onChanged: (v) => prefs.setSetting('traktSecret', v.trim())),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: const Text('Marquer vu automatiquement à la fin'),
          value: prefs.settingBool('traktScrobble', true),
          onChanged: (v) async { await prefs.setSetting('traktScrobble', v); setState(() {}); },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: const Text('Recommandations « Recommandé pour vous »'),
          value: prefs.settingBool('traktRecommendationsEnabled', true),
          onChanged: (v) async { await prefs.setSetting('traktRecommendationsEnabled', v); setState(() {}); },
        ),
        const SizedBox(height: 10),
        if (connected)
          FilledButton.tonalIcon(onPressed: () async { await ref.read(traktServiceProvider).disconnect(); setState(() {}); }, icon: const Icon(Icons.link_off), label: const Text('✓ Connecté — Déconnecter'))
        else
          FilledButton.icon(onPressed: _connectTrakt, icon: const Icon(Icons.link), label: const Text('Connecter (code device)')),
      ]),
    ];
  }

  // --- 🔄 Mise à jour automatique ---
  List<Widget> _autoRefresh(PrefsStore prefs) {
    final cur = ref.watch(autoRefreshControllerProvider);
    final last = int.tryParse(prefs.settingStr('lastRefresh', '0')) ?? 0;
    return [
      _card([
        const Text('Recharge périodiquement chaînes, films, séries et EPG en arrière-plan.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Row(children: [
          const Text('Fréquence', style: TextStyle(color: KtvColors.muted, fontSize: 13)),
          const Spacer(),
          DropdownButton<int>(
            value: cur,
            dropdownColor: KtvColors.panel2,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Désactivée')),
              DropdownMenuItem(value: 30, child: Text('Toutes les 30 min')),
              DropdownMenuItem(value: 60, child: Text('Toutes les heures')),
              DropdownMenuItem(value: 180, child: Text('Toutes les 3 h')),
              DropdownMenuItem(value: 360, child: Text('Toutes les 6 h')),
            ],
            onChanged: (v) async { if (v != null) { await ref.read(autoRefreshControllerProvider.notifier).setMinutes(v); setState(() {}); } },
          ),
        ]),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(onPressed: () { ref.read(autoRefreshControllerProvider.notifier).refreshNow(); setState(() {}); _toast('Actualisé'); }, icon: const Icon(Icons.refresh), label: const Text('Actualiser maintenant')),
        if (last > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Dernière actualisation : ${_dateTime(last)}', style: const TextStyle(color: KtvColors.muted, fontSize: 11.5))),
      ]),
    ];
  }

  // --- 💾 Enregistrements ---
  List<Widget> _recordings() {
    final recs = ref.watch(recordingControllerProvider);
    final rec = ref.watch(recordingControllerProvider.notifier);
    return [
      _card([
        const Text('Bouton ● sur une chaîne Live pour enregistrer, ⏱ dans le lecteur pour programmer. La lecture continue pendant l\'enregistrement.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 10),
        if (recs.isEmpty)
          const Text('Aucun enregistrement.', style: TextStyle(color: KtvColors.muted, fontSize: 13))
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    if (r.status == RecStatus.scheduled && r.startAt != null)
                      Text('Programmé — commence à ${_hhmm(r.startAt!)}', style: const TextStyle(color: KtvColors.muted, fontSize: 11))
                    else if (r.status == RecStatus.recording)
                      const Text('En cours…', style: TextStyle(color: KtvColors.rec, fontSize: 11)),
                  ]),
                ),
                if (r.status == RecStatus.recording)
                  TextButton(onPressed: () => rec.stop(), child: const Text('Arrêter'))
                else if (r.status == RecStatus.scheduled)
                  TextButton(onPressed: () => rec.cancelScheduled(r.id), child: const Text('Annuler')),
              ]),
            ),
      ]),
    ];
  }

  // --- ⬇️ Téléchargements ---
  List<Widget> _downloads() {
    final jobs = ref.watch(downloadControllerProvider);
    return [
      _card([
        if (jobs.isEmpty)
          const Text('Aucun téléchargement. Bouton ⬇ sur un film ou un épisode.', style: TextStyle(color: KtvColors.muted, fontSize: 13))
        else
          for (final j in jobs.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(j.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: j.status == DownloadStatus.done ? 1 : (j.progress == 0 ? null : j.progress),
                      minHeight: 4,
                      backgroundColor: KtvColors.panel2,
                      valueColor: AlwaysStoppedAnimation(j.status == DownloadStatus.error ? KtvColors.rec : KtvColors.accent),
                    ),
                  ]),
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
                  IconButton(icon: const Icon(Icons.close, size: 16, color: KtvColors.muted), onPressed: () => ref.read(downloadControllerProvider.notifier).cancelCurrent()),
              ]),
            ),
      ]),
    ];
  }

  // --- 👥 Profils ---
  List<Widget> _profiles() {
    final prefs = ref.read(prefsProvider);
    final prof = ref.watch(authControllerProvider);
    final profiles = prefs.profiles();
    return [
      _card([
        for (final p in profiles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.label),
            subtitle: Text(p.srv, style: const TextStyle(color: KtvColors.muted, fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (p.id == prof?.id) const Icon(Icons.check_circle, color: KtvColors.accent, size: 18),
              if (p.id != prof?.id) TextButton(onPressed: () => ref.read(authControllerProvider.notifier).switchTo(p), child: const Text('Activer')),
              IconButton(icon: const Icon(Icons.delete_outline, color: KtvColors.muted), onPressed: () => ref.read(authControllerProvider.notifier).deleteProfile(p.id)),
            ]),
          ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: const Icon(Icons.logout), label: const Text('Se déconnecter')),
      ]),
    ];
  }

  // --- ⬆️ Application ---
  List<Widget> _app() {
    return [
      _card([
        const Text('KTV — Flutter + media_kit', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Version 0.1.4', style: TextStyle(color: KtvColors.muted, fontSize: 13)),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _openUrl('https://github.com/khalilbenaz/ktv-flutter/releases'),
          icon: const Icon(Icons.system_update_alt),
          label: const Text('Voir les dernières versions'),
        ),
        const SizedBox(height: 8),
        const SelectableText('github.com/khalilbenaz/ktv-flutter', style: TextStyle(color: KtvColors.accent2, fontSize: 12)),
      ]),
    ];
  }

  // ---------- helpers ----------
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _openUrl(String url) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      }
    } catch (_) {}
  }

  String _date(String epochSecStr, {required String ifEmpty}) {
    final s = int.tryParse(epochSecStr) ?? 0;
    if (s <= 0) return ifEmpty;
    final d = DateTime.fromMillisecondsSinceEpoch(s * 1000);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _dateTime(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${_hhmm(epochMs)}';
  }

  String _hhmm(int epochMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: KtvColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: KtvColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _cell(String k, String v, {bool? ok}) => SizedBox(
        width: 220,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: const TextStyle(color: KtvColors.muted, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ok == null ? KtvColors.txt : (ok ? KtvColors.accent : KtvColors.rec))),
        ]),
      );

  Widget _line(String k, String v) => Row(children: [
        SizedBox(width: 120, child: Text(k, style: const TextStyle(color: KtvColors.muted))),
        Expanded(child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);

  // ---------- Trakt device flow ----------
  Future<void> _connectTrakt() async {
    final trakt = ref.read(traktServiceProvider);
    if (ref.read(prefsProvider).settingStr('traktClientId').isEmpty) {
      _toast('Renseigne d\'abord le Client ID.');
      return;
    }
    Map<String, dynamic> code;
    try {
      code = await trakt.requestDeviceCode();
    } catch (_) {
      if (mounted) _toast('Échec de la demande de code Trakt.');
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
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Va sur :', style: TextStyle(color: KtvColors.muted)),
            SelectableText(url, style: const TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('et saisis le code :', style: TextStyle(color: KtvColors.muted)),
            SelectableText(userCode, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3)),
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: KtvColors.accent),
          ]),
        );
      },
    ).then((_) => poll?.cancel());
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavTab({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: active ? KtvColors.panel2 : null, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(icon, size: 18, color: active ? KtvColors.accent : KtvColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? KtvColors.txt : KtvColors.muted))),
          ]),
        ),
      );
}
