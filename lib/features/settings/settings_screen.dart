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
import '../../services/sync/sync_providers.dart';
import '../../services/update/update_service.dart';
import '../../services/downloads/download_service.dart';
import '../../services/recording/recording_service.dart';
import '../../services/epg/epg_providers.dart';
import '../home/home_providers.dart';
import '../auth/auth_controller.dart';
import '../categories/category_prefs.dart';
import '../categories/category_manager_screen.dart';
import '../../l10n/app_localizations.dart';

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
  final _syncPassCtrl = TextEditingController();
  final _syncEndpointCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ctrl = ref.read(syncControllerProvider.notifier);
    _syncEndpointCtrl.text = ctrl.endpoint;
  }

  @override
  void dispose() {
    _syncPassCtrl.dispose();
    _syncEndpointCtrl.dispose();
    super.dispose();
  }

  static const _tabIcons = <IconData>[
    Icons.person_rounded, Icons.play_circle_outline, Icons.palette_rounded, Icons.home_rounded,
    Icons.event_note_rounded, Icons.movie_filter_rounded, Icons.category_rounded, Icons.theaters_rounded,
    Icons.sync_rounded, Icons.cloud_sync_rounded, Icons.autorenew_rounded, Icons.fiber_manual_record,
    Icons.download_rounded, Icons.history_rounded, Icons.speed_rounded, Icons.switch_account_rounded,
    Icons.info_outline_rounded,
  ];

  static String _tabName(L l, int i) => [
        l.tabAccount, l.tabPlayback, l.tabTheme, l.tabHome, l.tabEpg, l.tabCatalog, l.tabCategories,
        l.tabTmdb, l.tabTrakt, l.tabSync, l.tabAutoUpdate, l.tabRecordings, l.tabDownloads, l.tabHistory,
        l.tabDiagnostic, l.tabProfiles, l.tabApp,
      ][i];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_settingsTabProvider);
    final prefs = ref.read(prefsProvider);
    final l = L.of(context)!;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                    child: Text(l.settingsTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  for (var i = 0; i < _tabIcons.length; i++)
                    _NavTab(icon: _tabIcons[i], label: _tabName(l, i), active: i == tab, onTap: () => ref.read(_settingsTabProvider.notifier).state = i),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 1, color: KtvColors.line),
          // Contenu de la section.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(_tabName(l, tab), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                ...switch (tab) {
                  0 => _account(),
                  1 => _playback(prefs),
                  2 => _theme(prefs),
                  3 => _homeCategories(prefs),
                  4 => _epg(),
                  5 => _catalog(),
                  6 => _categories(),
                  7 => _tmdb(prefs),
                  8 => _trakt(prefs),
                  9 => _syncDevices(prefs),
                  10 => _autoRefresh(prefs),
                  11 => _recordings(),
                  12 => _downloads(),
                  13 => _history(),
                  14 => _diagnostic(),
                  15 => _profiles(),
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
        loading: () => Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: KtvColors.accent))),
        error: (_, _) => Text(L.of(context)!.sAccErr, style: TextStyle(color: KtvColors.muted)),
        data: (ui) {
          if (ui == null) return Text(L.of(context)!.sNotConnected, style: TextStyle(color: KtvColors.muted));
          return _card([
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _cell(L.of(context)!.sStatus, ui.status.isEmpty ? '—' : ui.status, ok: ui.status.toLowerCase() == 'active'),
                _cell(L.of(context)!.sExpiration, _date(ui.expDate, ifEmpty: L.of(context)!.sUnlimited)),
                _cell(L.of(context)!.sConnections, '${ui.activeCons} / ${ui.maxCons}'),
                _cell(L.of(context)!.sTrial, ui.isTrial ? L.of(context)!.sYes : L.of(context)!.sNo),
                _cell(L.of(context)!.sUser, prof?.usr ?? '—'),
                _cell(L.of(context)!.sServer, prof?.srv ?? '—'),
                _cell(L.of(context)!.sCreatedOn, _date(ui.createdAt, ifEmpty: '—')),
                if (ui.timezone.isNotEmpty) _cell(L.of(context)!.sTimezone, ui.timezone),
                if (ui.allowedFormats.isNotEmpty) _cell(L.of(context)!.sFormats, ui.allowedFormats.join(', ')),
              ],
            ),
            if (ui.message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(ui.message, style: TextStyle(color: KtvColors.accent2, fontSize: 12.5)),
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
        Text(L.of(context)!.sBufferHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          for (final p in [('low', L.of(context)!.sBufLow), ('balanced', L.of(context)!.sBufBalanced), ('stable', L.of(context)!.sBufStable)])
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
        Text(L.of(context)!.sBufApplied, style: TextStyle(color: KtvColors.muted, fontSize: 11.5)),
        Divider(height: 24, color: KtvColors.line),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: Text(L.of(context)!.sAutoplay),
          subtitle: Text(L.of(context)!.sAutoplayHint, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
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
      data: (idx) => idx.byId.isEmpty ? L.of(context)!.sNoData : 'activé · ${idx.byId.length} chaînes',
    );
    return [
      _card([
        Text(L.of(context)!.sEpgHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        _line('État', status),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () {
            ref.invalidate(epgIndexProvider);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.of(context)!.sEpgReloading)));
          },
          icon: const Icon(Icons.refresh),
          label: Text(L.of(context)!.sRefreshEpg),
        ),
      ]),
    ];
  }

  // --- 🎬 Catalogue ---
  List<Widget> _catalog() {
    return [
      _card([
        Text(L.of(context)!.sCatalogHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.tonalIcon(onPressed: () { ref.invalidate(allVodProvider); ref.invalidate(latestVodProvider); _toast(L.of(context)!.sMoviesRefreshed); }, icon: Icon(Icons.movie_rounded), label: Text(L.of(context)!.sRefreshMovies)),
          FilledButton.tonalIcon(onPressed: () { ref.invalidate(allSeriesProvider); ref.invalidate(latestSeriesProvider); _toast(L.of(context)!.sSeriesRefreshed); }, icon: Icon(Icons.grid_view_rounded), label: Text(L.of(context)!.sRefreshSeries)),
          FilledButton.icon(onPressed: () { ref.read(autoRefreshControllerProvider.notifier).refreshNow(); _toast(L.of(context)!.sCatalogRefreshed); }, icon: Icon(Icons.refresh), label: Text(L.of(context)!.sRefreshAll)),
        ]),
      ]),
    ];
  }

  // --- 🗂 Catégories (garder/masquer par section) ---
  List<Widget> _categories() {
    Widget row(CatSection section, IconData icon) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: KtvColors.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(section.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CategoryManagerScreen(section: section)),
                ),
                icon: const Icon(Icons.tune, size: 18),
                label: Text(L.of(context)!.sManage),
              ),
            ],
          ),
        );
    return [
      _card([
        Text(
          L.of(context)!.sCatManageHint + L.of(context)!.sCatDefault,
          style: TextStyle(color: KtvColors.muted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 12),
        row(CatSection.live, Icons.live_tv_rounded),
        Divider(height: 16, color: KtvColors.line),
        row(CatSection.vod, Icons.movie_rounded),
        Divider(height: 16, color: KtvColors.line),
        row(CatSection.series, Icons.grid_view_rounded),
      ]),
    ];
  }

  // --- 🎬 Enrichissement TMDB ---
  List<Widget> _tmdb(PrefsStore prefs) {
    final enabled = prefs.settingBool('tmdbEnabled', true);
    final lang = prefs.settingStr('tmdbLang', 'fr-FR');
    return [
      _card([
        Text(L.of(context)!.sTmdbHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: Text(L.of(context)!.sTmdbEnable),
          value: enabled,
          onChanged: (v) async { await prefs.setSetting('tmdbEnabled', v); setState(() {}); },
        ),
        Row(children: [
          const SizedBox(width: 4),
          Text(L.of(context)!.sTmdbLang, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
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
        Text(L.of(context)!.sTmdbKeyHint, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          obscureText: true,
          decoration: InputDecoration(hintText: L.of(context)!.sTmdbKey),
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
        Text(L.of(context)!.sTraktHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 10),
        TextField(decoration: InputDecoration(hintText: L.of(context)!.sClientId), controller: TextEditingController(text: prefs.settingStr('traktClientId')), onChanged: (v) => prefs.setSetting('traktClientId', v.trim())),
        const SizedBox(height: 8),
        TextField(obscureText: true, decoration: InputDecoration(hintText: L.of(context)!.sClientSecret), controller: TextEditingController(text: prefs.settingStr('traktSecret')), onChanged: (v) => prefs.setSetting('traktSecret', v.trim())),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: Text(L.of(context)!.sTraktScrobble),
          value: prefs.settingBool('traktScrobble', true),
          onChanged: (v) async { await prefs.setSetting('traktScrobble', v); setState(() {}); },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: KtvColors.accent,
          title: Text(L.of(context)!.sTraktReco),
          value: prefs.settingBool('traktRecommendationsEnabled', true),
          onChanged: (v) async { await prefs.setSetting('traktRecommendationsEnabled', v); setState(() {}); },
        ),
        const SizedBox(height: 10),
        if (connected)
          FilledButton.tonalIcon(onPressed: () async { await ref.read(traktServiceProvider).disconnect(); setState(() {}); }, icon: const Icon(Icons.link_off), label: const Text('✓ Connecté — Déconnecter'))
        else
          FilledButton.icon(onPressed: _connectTrakt, icon: Icon(Icons.link), label: Text(L.of(context)!.sTraktConnect)),
      ]),
    ];
  }

  // --- ☁️ Synchro appareils (compte Trakt + chiffrement) ---
  List<Widget> _syncDevices(PrefsStore prefs) {
    final ctrl = ref.read(syncControllerProvider.notifier);
    final st = ref.watch(syncControllerProvider);
    final connected = prefs.traktConnected;
    final enabled = ctrl.enabled;

    return [
      _card([
        Text(
          L.of(context)!.sSyncHint1 + L.of(context)!.sSyncHint2,
          style: TextStyle(color: KtvColors.muted, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 14),
        if (!connected)
          Row(children: [
            Icon(Icons.info_outline, size: 18, color: KtvColors.accent2),
            const SizedBox(width: 8),
            Expanded(child: Text(L.of(context)!.sSyncNeedTrakt, style: TextStyle(color: KtvColors.accent2, fontSize: 12.5))),
          ])
        else ...[
          Text(L.of(context)!.sPassphraseLabel, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _syncPassCtrl,
            decoration: InputDecoration(hintText: enabled ? L.of(context)!.sPassphraseSet : L.of(context)!.sPassphraseChoose),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            if (!enabled)
              FilledButton.icon(
                onPressed: st.status == SyncStatus.syncing
                    ? null
                    : () async {
                        if (_syncPassCtrl.text.trim().length < 4) { _toast(L.of(context)!.sPassphraseShort); return; }
                        await ctrl.activate(_syncPassCtrl.text.trim());
                        _syncPassCtrl.clear();
                        setState(() {});
                      },
                icon: const Icon(Icons.cloud_done_outlined),
                label: Text(L.of(context)!.sSyncEnable),
              )
            else ...[
              FilledButton.icon(
                onPressed: st.status == SyncStatus.syncing ? null : () async {
                  if (_syncPassCtrl.text.trim().isNotEmpty) {
                    await ctrl.activate(_syncPassCtrl.text.trim());
                  } else {
                    await ctrl.syncNow();
                  }
                  _syncPassCtrl.clear();
                  setState(() {});
                },
                icon: st.status == SyncStatus.syncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: Text(L.of(context)!.sSyncNow),
              ),
              FilledButton.tonalIcon(
                onPressed: () async { await ctrl.disable(); setState(() {}); },
                icon: const Icon(Icons.cloud_off),
                label: Text(L.of(context)!.sDisable),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              switch (st.status) { SyncStatus.ok => Icons.check_circle, SyncStatus.error => Icons.error_outline, SyncStatus.syncing => Icons.sync, _ => Icons.cloud_queue },
              size: 16,
              color: st.status == SyncStatus.error ? KtvColors.rec : (st.status == SyncStatus.ok ? KtvColors.accent : KtvColors.muted),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              st.message ?? (st.lastAt > 0 ? 'Dernière synchro : ${_dateTime(st.lastAt)}' : (enabled ? L.of(context)!.sSyncEnabledNoSync : L.of(context)!.sSyncDisabled)),
              style: TextStyle(color: st.status == SyncStatus.error ? KtvColors.rec : KtvColors.muted, fontSize: 12),
            )),
          ]),
        ],
        Divider(height: 26, color: KtvColors.line),
        Text(L.of(context)!.sSyncServer, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _syncEndpointCtrl,
          decoration: const InputDecoration(hintText: 'https://ktv-sync.<compte>.workers.dev'),
          onChanged: (v) => ctrl.setEndpoint(v),
        ),
      ]),
    ];
  }

  // --- 🔄 Mise à jour automatique ---
  List<Widget> _autoRefresh(PrefsStore prefs) {
    final cur = ref.watch(autoRefreshControllerProvider);
    final last = int.tryParse(prefs.settingStr('lastRefresh', '0')) ?? 0;
    return [
      _card([
        Text(L.of(context)!.sAutoRefreshHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        Row(children: [
          Text(L.of(context)!.sFrequency, style: TextStyle(color: KtvColors.muted, fontSize: 13)),
          const Spacer(),
          DropdownButton<int>(
            value: cur,
            dropdownColor: KtvColors.panel2,
            underline: const SizedBox(),
            items: [
              DropdownMenuItem(value: 0, child: Text(L.of(context)!.sFreqOff)),
              DropdownMenuItem(value: 30, child: Text(L.of(context)!.sEvery30)),
              DropdownMenuItem(value: 60, child: Text(L.of(context)!.sEvery1h)),
              DropdownMenuItem(value: 180, child: Text(L.of(context)!.sEvery3h)),
              DropdownMenuItem(value: 360, child: Text(L.of(context)!.sEvery6h)),
            ],
            onChanged: (v) async { if (v != null) { await ref.read(autoRefreshControllerProvider.notifier).setMinutes(v); setState(() {}); } },
          ),
        ]),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(onPressed: () { ref.read(autoRefreshControllerProvider.notifier).refreshNow(); setState(() {}); _toast(L.of(context)!.sRefreshed); }, icon: Icon(Icons.refresh), label: Text(L.of(context)!.sRefreshNow)),
        if (last > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Dernière actualisation : ${_dateTime(last)}', style: TextStyle(color: KtvColors.muted, fontSize: 11.5))),
      ]),
    ];
  }

  // --- 💾 Enregistrements ---
  List<Widget> _recordings() {
    final recs = ref.watch(recordingControllerProvider);
    final rec = ref.watch(recordingControllerProvider.notifier);
    return [
      _card([
        Text('Bouton ● sur une chaîne Live pour enregistrer, ⏱ dans le lecteur pour programmer. La lecture continue pendant l\'enregistrement.', style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        _folderRow('recordingsDir', 'Documents/KTV Enregistrements'),
        Divider(height: 24, color: KtvColors.line),
        if (recs.isEmpty)
          Text(L.of(context)!.sNoRecording, style: TextStyle(color: KtvColors.muted, fontSize: 13))
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
                      Text('Programmé — commence à ${_hhmm(r.startAt!)}', style: TextStyle(color: KtvColors.muted, fontSize: 11))
                    else if (r.status == RecStatus.recording)
                      Text(L.of(context)!.sInProgress, style: TextStyle(color: KtvColors.rec, fontSize: 11)),
                  ]),
                ),
                if (r.status == RecStatus.recording)
                  TextButton(onPressed: () => rec.stop(), child: Text(L.of(context)!.sStop))
                else if (r.status == RecStatus.scheduled)
                  TextButton(onPressed: () => rec.cancelScheduled(r.id), child: Text(L.of(context)!.sCancel)),
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
        Divider(height: 24, color: KtvColors.line),
        if (jobs.isEmpty)
          Text(L.of(context)!.sNoDownload, style: TextStyle(color: KtvColors.muted, fontSize: 13))
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
                    DownloadStatus.error => L.of(context)!.sFailed2,
                    DownloadStatus.canceled => L.of(context)!.sCanceled2,
                    DownloadStatus.downloading => '${(j.progress * 100).round()}%',
                    DownloadStatus.queued => L.of(context)!.sQueued2,
                  },
                  style: TextStyle(color: KtvColors.muted, fontSize: 12),
                ),
                if (j.status == DownloadStatus.downloading)
                  IconButton(icon: Icon(Icons.close, size: 16, color: KtvColors.muted), onPressed: () => ref.read(downloadControllerProvider.notifier).cancelCurrent()),
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
            subtitle: Text(p.srv, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (p.id == prof?.id) Icon(Icons.check_circle, color: KtvColors.accent, size: 18),
              if (p.id != prof?.id) TextButton(onPressed: () => ref.read(authControllerProvider.notifier).switchTo(p), child: Text(L.of(context)!.sActivate)),
              IconButton(icon: Icon(Icons.delete_outline, color: KtvColors.muted), onPressed: () => ref.read(authControllerProvider.notifier).deleteProfile(p.id)),
            ]),
          ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: () => ref.read(authControllerProvider.notifier).logout(), icon: Icon(Icons.logout), label: Text(L.of(context)!.sLogout)),
      ]),
    ];
  }

  // --- 🎨 Thème (accent) ---
  List<Widget> _theme(PrefsStore prefs) {
    const labels = {
      'orange': 'Orange', 'blue': 'Bleu', 'green': 'Vert', 'purple': 'Violet',
      'red': 'Rouge', 'pink': 'Rose', 'teal': 'Turquoise',
    };
    final current = prefs.settingStr('accentColor', 'orange');
    final light = prefs.settingBool('themeLight', false);
    final lang = prefs.settingStr('appLang', 'system');
    return [
      _card([
        Text(L.of(context)!.language, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: lang,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'system', child: Text(L.of(context)!.langSystem)),
            DropdownMenuItem(value: 'fr', child: Text(L.of(context)!.langFrench)),
            DropdownMenuItem(value: 'en', child: Text(L.of(context)!.langEnglish)),
            DropdownMenuItem(value: 'ar', child: Text(L.of(context)!.langArabic)),
          ],
          onChanged: (v) async {
            if (v == null) return;
            await prefs.setSetting('appLang', v);
            ref.read(localeProvider.notifier).state = localeForCode(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 18),
        Text(L.of(context)!.themeAppearance, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: false, icon: Icon(Icons.dark_mode, size: 16), label: Text(L.of(context)!.themeDark)),
            ButtonSegment(value: true, icon: Icon(Icons.light_mode, size: 16), label: Text(L.of(context)!.themeLight)),
          ],
          selected: {light},
          onSelectionChanged: (s) async {
            await prefs.setSetting('themeLight', s.first);
            KtvColors.apply(light: s.first, accentKey: prefs.settingStr('accentColor', 'orange'));
            ref.read(themeVersionProvider.notifier).state++;
            setState(() {});
          },
        ),
        const SizedBox(height: 18),
        Text(L.of(context)!.themeAccent, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        Text(L.of(context)!.themeAccentHint, style: TextStyle(color: KtvColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final e in KtvColors.accents.entries)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await prefs.setSetting('accentColor', e.key);
                  KtvColors.apply(light: prefs.settingBool('themeLight', false), accentKey: e.key);
                  ref.read(themeVersionProvider.notifier).state++;
                  setState(() {});
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [e.value.$1, e.value.$2]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: current == e.key ? Colors.white : KtvColors.line, width: current == e.key ? 3 : 1),
                    ),
                    child: current == e.key ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 6),
                  Text(labels[e.key] ?? e.key, style: TextStyle(fontSize: 11.5, color: KtvColors.muted)),
                ]),
              ),
          ],
        ),
      ]),
    ];
  }

  // --- 🏠 Accueil (rangées affichées) ---
  List<Widget> _homeCategories(PrefsStore prefs) {
    const rails = [
      ('home_favs', 'Chaînes favorites'),
      ('home_mediafavs', 'Films & séries favoris'),
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
        Text(L.of(context)!.sHomeRowsHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
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
          Expanded(child: Text('${recent.length} entrée(s)', style: TextStyle(color: KtvColors.muted, fontSize: 12.5))),
          if (recent.isNotEmpty)
            TextButton.icon(
              onPressed: () async { final msg = L.of(context)!.sHistoryCleared; await ref.read(prefsProvider).clearRecent(); setState(() {}); _toast(msg); },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(L.of(context)!.sClear),
            ),
        ]),
        if (recent.isEmpty)
          Text(L.of(context)!.sNoHistory, style: TextStyle(color: KtvColors.muted, fontSize: 13))
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
              subtitle: e.subtitle != null ? Text(e.subtitle!, style: TextStyle(color: KtvColors.muted, fontSize: 11)) : null,
              trailing: Icon(Icons.play_arrow, color: KtvColors.accent2),
              onTap: () => PlayLauncher.recent(context, ref, e),
            ),
      ]),
    ];
  }

  // --- 📶 Diagnostic du fournisseur ---
  List<Widget> _diagnostic() {
    return [
      _card([
        Text(L.of(context)!.sDiagHint, style: TextStyle(color: KtvColors.muted, fontSize: 12.5)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _diagRunning ? null : _runDiagnostic,
          icon: _diagRunning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.speed),
          label: Text(L.of(context)!.sRunTest),
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
        Text('Version $kAppVersion', style: TextStyle(color: KtvColors.muted, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          FilledButton.icon(
            onPressed: _checkingUpdate ? null : _checkUpdate,
            icon: _checkingUpdate
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.system_update_alt),
            label: Text(L.of(context)!.sCheckUpdates),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: () => _openUrl('https://github.com/khalilbenaz/ktv-flutter/releases'), child: Text(L.of(context)!.sSeeReleases)),
        ]),
        if (u != null) ...[
          const SizedBox(height: 14),
          if (u.isNewer) ...[
            Text('Nouvelle version disponible : v${u.tag}', style: TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
            if (u.notes.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(color: KtvColors.panel2, borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(child: Text(u.notes, style: TextStyle(fontSize: 12, color: KtvColors.muted))),
              ),
            const SizedBox(height: 10),
            if (_dlProgress == null)
              FilledButton.tonalIcon(onPressed: u.assetUrl == null ? null : _downloadUpdate, icon: const Icon(Icons.download_rounded), label: Text(u.assetUrl == null ? 'Archive indisponible' : 'Télécharger v${u.tag}'))
            else if (_dlProgress! < 1)
              Row(children: [Expanded(child: LinearProgressIndicator(value: _dlProgress, backgroundColor: KtvColors.panel2, valueColor: AlwaysStoppedAnimation(KtvColors.accent))), const SizedBox(width: 10), Text('${(_dlProgress! * 100).round()}%')])
            else
              Text('✓ Téléchargé — remplace KTV.app dans /Applications puis relance.', style: TextStyle(color: KtvColors.accent, fontSize: 12.5)),
          ] else
            Text(L.of(context)!.sUpToDate, style: TextStyle(color: KtvColors.accent, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 10),
        SelectableText('github.com/khalilbenaz/ktv-flutter', style: TextStyle(color: KtvColors.accent2, fontSize: 12)),
      ]),
    ];
  }

  Future<void> _checkUpdate() async {
    setState(() { _checkingUpdate = true; _update = null; _dlProgress = null; });
    final info = await ref.read(updateServiceProvider).check();
    if (!mounted) return;
    setState(() { _checkingUpdate = false; _update = info; });
    if (info == null) _toast(L.of(context)!.sUpdateErr);
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
      _toast(L.of(context)!.sDownloadErr);
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
          Icon(Icons.folder_open, size: 16, color: KtvColors.accent2),
          const SizedBox(width: 8),
          Expanded(child: Text(path.isEmpty ? '$defLabel (par défaut)' : path, style: TextStyle(color: KtvColors.muted, fontSize: 12.5))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          FilledButton.tonalIcon(onPressed: () => _pickFolder(key), icon: Icon(Icons.drive_folder_upload, size: 18), label: Text(L.of(context)!.sChangeFolder)),
          TextButton.icon(onPressed: () => _openFolder(key, defLabel), icon: Icon(Icons.open_in_new, size: 16), label: Text(L.of(context)!.sOpen)),
          if (path.isNotEmpty) TextButton(onPressed: () async { await prefs.setSetting(key, null); setState(() {}); }, child: const Text('Réinitialiser')),
        ]),
      ],
    );
  }

  Future<void> _pickFolder(String key) async {
    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: L.of(context)!.sChooseFolder);
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
          Text(k, style: TextStyle(color: KtvColors.muted, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ok == null ? KtvColors.txt : (ok ? KtvColors.accent : KtvColors.rec))),
        ]),
      );

  Widget _line(String k, String v) => Row(children: [
        SizedBox(width: 120, child: Text(k, style: TextStyle(color: KtvColors.muted))),
        Expanded(child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);

  // ---------- Trakt device flow ----------
  Future<void> _connectTrakt() async {
    final trakt = ref.read(traktServiceProvider);
    if (ref.read(prefsProvider).settingStr('traktClientId').isEmpty) {
      _toast(L.of(context)!.sNeedClientId);
      return;
    }
    Map<String, dynamic> code;
    try {
      code = await trakt.requestDeviceCode();
    } catch (_) {
      if (mounted) _toast(L.of(context)!.sTraktCodeErr);
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
          title: Text(L.of(context)!.sTraktConnDialog),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(L.of(context)!.sGoTo, style: TextStyle(color: KtvColors.muted)),
            SelectableText(url, style: TextStyle(color: KtvColors.accent2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(L.of(context)!.sEnterCode, style: TextStyle(color: KtvColors.muted)),
            SelectableText(userCode, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 3)),
            const SizedBox(height: 12),
            CircularProgressIndicator(color: KtvColors.accent),
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
