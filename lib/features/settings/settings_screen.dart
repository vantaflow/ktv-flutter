import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/models/models.dart';
import '../player/play_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../core/version.dart';
import '../../core/storage/prefs_store.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/update/update_service.dart';
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
  bool _checkingUpdate = false;
  UpdateInfo? _update;
  double? _dlProgress;
  bool _diagRunning = false;
  String? _diagText;

  static const _tabs = [
    (icon: Icons.person_rounded, label: 'Compte & abonnement'),
    (icon: Icons.play_circle_outline, label: 'Lecture & tampon'),
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.event_note_rounded, label: 'EPG externe'),
    (icon: Icons.movie_filter_rounded, label: 'Catalogue'),
    (icon: Icons.theaters_rounded, label: 'Enrichissement TMDB'),
    (icon: Icons.sync_rounded, label: 'Synchronisation Trakt'),
    (icon: Icons.autorenew_rounded, label: 'Mise à jour auto'),
    (icon: Icons.fiber_manual_record, label: 'Enregistrements'),
    (icon: Icons.download_rounded, label: 'Téléchargements'),
    (icon: Icons.history_rounded, label: 'Historique'),
    (icon: Icons.speed_rounded, label: 'Diagnostic'),
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
                ...switch (_tabs[tab].label) {
                  'Compte & abonnement' => _account(),
                  'Lecture & tampon' => _playback(prefs),
                  'Accueil' => _homeCategories(prefs),
                  'EPG externe' => _epg(),
                  'Catalogue' => _catalog(),
                  'Enrichissement TMDB' => _tmdb(prefs),
                  'Synchronisation Trakt' => _trakt(prefs),
                  'Mise à jour auto' => _autoRefresh(prefs),
                  'Enregistrements' => _recordings(),
                  'Téléchargements' => _downloads(),
                  'Historique' => _history(),
                  'Diagnostic' => _diagnostic(),
                  'Profils' => _profiles(),
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
        const Divider(height: 24, color: KtvColors.line),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: const Text('Lecture auto de l\'épisode suivant'),
          subtitle: const Text('Enchaîne la série à la fin d\'un épisode', style: TextStyle(color: KtvColors.muted, fontSize: 12)),
          value: prefs.settingBool('autoplayNext', true),
          onChanged: (v) async { await prefs.setSetting('autoplayNext', v); setState(() {}); },
        ),
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
        const SizedBox(height: 12),
        _folderRow('recordingsDir', 'Documents/KTV Enregistrements'),
        const Divider(height: 24, color: KtvColors.line),
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
        _folderRow('downloadsDir', 'Documents/KTV Téléchargements'),
        const Divider(height: 24, color: KtvColors.line),
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

  // --- 🏠 Accueil (rangées affichées) ---
  List<Widget> _homeCategories(PrefsStore prefs) {
    const rails = [
      ('home_favs', 'Chaînes favorites'),
      ('home_resume', 'Reprendre la lecture'),
      ('home_recent', 'Vu récemment'),
      ('home_watchlist', 'Ma liste (Trakt)'),
      ('home_recoMovies', 'Recommandé pour vous'),
      ('home_recoSeries', 'Séries recommandées'),
      ('home_latestMovies', 'Derniers films ajoutés'),
      ('home_latestSeries', 'Dernières séries ajoutées'),
    ];
    return [
      _card([
        const Text('Coche les rangées à afficher sur l\'accueil.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        for (final r in rails)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: KtvColors.accent,
            title: Text(r.$2),
            value: prefs.settingBool(r.$1, true),
            onChanged: (v) async { await prefs.setSetting(r.$1, v); setState(() {}); },
          ),
      ]),
    ];
  }

  // --- 🕘 Historique complet ---
  List<Widget> _history() {
    final recent = ref.read(prefsProvider).recent();
    return [
      _card([
        Row(children: [
          Expanded(child: Text('${recent.length} entrée(s)', style: const TextStyle(color: KtvColors.muted, fontSize: 12.5))),
          if (recent.isNotEmpty)
            TextButton.icon(
              onPressed: () async { await ref.read(prefsProvider).clearRecent(); setState(() {}); _toast('Historique effacé'); },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Effacer'),
            ),
        ]),
        if (recent.isEmpty)
          const Text('Aucun historique.', style: TextStyle(color: KtvColors.muted, fontSize: 13))
        else
          for (final e in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                switch (e.kind) { MediaKind.live => Icons.live_tv, MediaKind.movie => Icons.movie_outlined, MediaKind.series => Icons.grid_view_rounded },
                color: KtvColors.muted,
                size: 20,
              ),
              title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: e.subtitle != null ? Text(e.subtitle!, style: const TextStyle(color: KtvColors.muted, fontSize: 11)) : null,
              trailing: const Icon(Icons.play_arrow, color: KtvColors.accent2),
              onTap: () => PlayLauncher.recent(context, ref, e),
            ),
      ]),
    ];
  }

  // --- 📶 Diagnostic du fournisseur ---
  List<Widget> _diagnostic() {
    return [
      _card([
        const Text('Teste la latence de l\'API, les connexions et le débit du flux.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _diagRunning ? null : _runDiagnostic,
          icon: _diagRunning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.speed),
          label: const Text('Lancer le test'),
        ),
        if (_diagText != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: KtvColors.panel2, borderRadius: BorderRadius.circular(10)),
            child: Text(_diagText!, style: const TextStyle(fontSize: 13, height: 1.5, fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ],
      ]),
    ];
  }

  Future<void> _runDiagnostic() async {
    setState(() { _diagRunning = true; _diagText = null; });
    final client = ref.read(xtreamClientProvider);
    final urls = ref.read(xtreamUrlsProvider);
    final sw = Stopwatch()..start();
    UserInfo? ui;
    try { ui = await client?.authenticate(); } catch (_) {}
    final latency = sw.elapsedMilliseconds;
    double mbps = 0;
    if (urls != null) {
      try {
        final dio = Dio();
        final sw2 = Stopwatch()..start();
        var bytes = 0;
        final rs = await dio.get<ResponseBody>(urls.xmltv(), options: Options(responseType: ResponseType.stream, headers: {'User-Agent': 'KTV'}));
        await for (final chunk in rs.data!.stream) {
          bytes += chunk.length;
          if (sw2.elapsedMilliseconds > 3000 || bytes > 8 * 1024 * 1024) break;
        }
        if (sw2.elapsedMilliseconds > 0) mbps = (bytes * 8 / 1e6) / (sw2.elapsedMilliseconds / 1000);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _diagRunning = false;
      _diagText = 'Latence API      : $latency ms\n'
          'Statut           : ${ui?.status ?? '—'}\n'
          'Connexions       : ${ui?.activeCons ?? '?'} / ${ui?.maxCons ?? '?'}\n'
          'Débit (approx.)  : ${mbps.toStringAsFixed(1)} Mb/s';
    });
  }

  // --- ⬆️ Application ---
  List<Widget> _app() {
    final u = _update;
    return [
      _card([
        const Text('KTV — Flutter + media_kit', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Version $kAppVersion', style: const TextStyle(color: KtvColors.muted, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          FilledButton.icon(
            onPressed: _checkingUpdate ? null : _checkUpdate,
            icon: _checkingUpdate
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.system_update_alt),
            label: const Text('Vérifier les mises à jour'),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: () => _openUrl('https://github.com/khalilbenaz/ktv-flutter/releases'), child: const Text('Voir les releases')),
        ]),
        if (u != null) ...[
          const SizedBox(height: 14),
          if (u.isNewer) ...[
            Text('Nouvelle version disponible : v${u.tag}', style: const TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
            if (u.notes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(color: KtvColors.panel2, borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(child: Text(u.notes, style: const TextStyle(fontSize: 12, color: KtvColors.muted))),
              ),
            const SizedBox(height: 10),
            if (_dlProgress == null)
              FilledButton.tonalIcon(onPressed: u.assetUrl == null ? null : _downloadUpdate, icon: const Icon(Icons.download_rounded), label: Text(u.assetUrl == null ? 'Archive indisponible' : 'Télécharger v${u.tag}'))
            else if (_dlProgress! < 1)
              Row(children: [Expanded(child: LinearProgressIndicator(value: _dlProgress, backgroundColor: KtvColors.panel2, valueColor: const AlwaysStoppedAnimation(KtvColors.accent))), const SizedBox(width: 10), Text('${(_dlProgress! * 100).round()}%')])
            else
              const Text('✓ Téléchargé — remplace KTV.app dans /Applications puis relance.', style: TextStyle(color: KtvColors.accent, fontSize: 12.5)),
          ] else
            const Text('✓ Vous avez la dernière version.', style: TextStyle(color: KtvColors.accent, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 10),
        const SelectableText('github.com/khalilbenaz/ktv-flutter', style: TextStyle(color: KtvColors.accent2, fontSize: 12)),
      ]),
    ];
  }

  Future<void> _checkUpdate() async {
    setState(() { _checkingUpdate = true; _update = null; _dlProgress = null; });
    final info = await ref.read(updateServiceProvider).check();
    if (!mounted) return;
    setState(() { _checkingUpdate = false; _update = info; });
    if (info == null) _toast('Impossible de vérifier les mises à jour.');
  }

  Future<void> _downloadUpdate() async {
    final u = _update;
    if (u == null) return;
    setState(() => _dlProgress = 0);
    final path = await ref.read(updateServiceProvider).download(u, onProgress: (p) { if (mounted) setState(() => _dlProgress = p); });
    if (!mounted) return;
    setState(() => _dlProgress = 1);
    if (path != null) {
      try {
        if (Platform.isMacOS) {
          await Process.run('open', ['-R', path]); // révèle dans le Finder
        } else if (Platform.isWindows) {
          await Process.run('explorer', ['/select,', path]);
        }
      } catch (_) {}
      _toast('Téléchargé : $path');
    } else {
      _toast('Échec du téléchargement.');
    }
  }

  // ---------- helpers ----------
  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// Ligne « Dossier … » + boutons Changer / Réinitialiser / Ouvrir.
  Widget _folderRow(String key, String defLabel) {
    final prefs = ref.read(prefsProvider);
    final path = prefs.settingStr(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.folder_open, size: 16, color: KtvColors.accent2),
          const SizedBox(width: 8),
          Expanded(child: Text(path.isEmpty ? '$defLabel (par défaut)' : path, style: const TextStyle(color: KtvColors.muted, fontSize: 12.5))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          FilledButton.tonalIcon(onPressed: () => _pickFolder(key), icon: const Icon(Icons.drive_folder_upload, size: 18), label: const Text('Changer le dossier…')),
          TextButton.icon(onPressed: () => _openFolder(key, defLabel), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Ouvrir')),
          if (path.isNotEmpty) TextButton(onPressed: () async { await prefs.setSetting(key, null); setState(() {}); }, child: const Text('Réinitialiser')),
        ]),
      ],
    );
  }

  Future<void> _pickFolder(String key) async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choisir le dossier');
    if (dir != null && dir.isNotEmpty) {
      await ref.read(prefsProvider).setSetting(key, dir);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openFolder(String key, String defLabel) async {
    var path = ref.read(prefsProvider).settingStr(key);
    if (path.isEmpty) {
      final docs = await getApplicationDocumentsDirectory();
      // defLabel = "Documents/<nom>"
      final name = defLabel.split('/').last;
      final folder = Directory('${docs.path}/$name')..createSync(recursive: true);
      path = folder.path;
    }
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [path]);
      }
    } catch (_) {}
  }

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
