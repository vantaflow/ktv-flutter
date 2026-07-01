import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/models/playback.dart';
import '../../core/providers.dart';
import '../../core/connection/connection_lock.dart';
import '../../core/storage/prefs_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../services/trakt/trakt_service.dart';
import '../../services/trakt/trakt_providers.dart';
import '../../services/recording/recording_service.dart';
import '../auth/auth_controller.dart';
import '../live/live_providers.dart';
import 'player_controls.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final PlaybackRequest request;
  const PlayerScreen({super.key, required this.request});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player = Player();
  late final VideoController _video = VideoController(_player);
  late final PrefsStore _prefs;
  late final ConnectionLock _lock;
  late final TraktService _trakt;
  final _subs = <StreamSubscription>[];
  final _focus = FocusNode();

  bool _playing = true;
  Duration _position = Duration.zero;
  Duration _bufferPos = Duration.zero;
  Duration? _mkDuration;
  double _volume = 1.0;
  bool _muted = false;
  bool _fullscreen = false;
  List<AudioTrack> _audio = const [];
  List<SubtitleTrack> _subtitle = const [];
  String? _curAudioId;
  String? _curSubId;
  bool _sidebarOpen = false;
  late String _title = widget.request.title;
  late String? _liveId = widget.request.liveStreamId;
  bool _resumeApplied = false;
  bool _watchedMarked = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _saveTimer;

  int? get _knownDurSec => widget.request.knownDurationSec ?? ((_mkDuration != null && _mkDuration!.inSeconds > 0) ? _mkDuration!.inSeconds : null);
  Duration? get _effDuration => _knownDurSec == null ? null : Duration(seconds: _knownDurSec!);

  @override
  void initState() {
    super.initState();
    _prefs = ref.read(prefsProvider);
    _lock = ref.read(connectionLockProvider);
    _trakt = ref.read(traktServiceProvider);
    // Tampon → propriété mpv (cache-secs) selon le réglage.
    const bufMap = {'low': '10', 'balanced': '30', 'stable': '60'};
    final secs = bufMap[_prefs.settingStr('bufferProfile', 'balanced')] ?? '30';
    try {
      (_player.platform as dynamic)?.setProperty('cache-secs', secs);
    } catch (_) {}
    // Si un autre flux (lecture/enregistrement) préempte, on coupe immédiatement.
    _lock.acquire(ConnUse.playback, onPreempt: () {
      try {
        _player.stop();
      } catch (_) {}
    });
    _wire();
    _player.open(Media(widget.request.url));
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveResume());
    _armHide();
  }

  void _wire() {
    _subs.add(_player.stream.playing.listen((v) => setState(() => _playing = v)));
    _subs.add(_player.stream.position.listen((p) {
      setState(() => _position = p);
      _maybeResume();
      _maybeMarkWatched();
    }));
    _subs.add(_player.stream.buffer.listen((b) => setState(() => _bufferPos = b)));
    _subs.add(_player.stream.duration.listen((d) => setState(() => _mkDuration = d)));
    _subs.add(_player.stream.volume.listen((v) => setState(() => _volume = (v / 100).clamp(0, 1))));
    _subs.add(_player.stream.tracks.listen((t) => setState(() {
          _audio = t.audio;
          _subtitle = t.subtitle;
        })));
    _subs.add(_player.stream.track.listen((t) => setState(() {
          _curAudioId = t.audio.id;
          _curSubId = t.subtitle.id;
        })));
  }

  void _maybeResume() {
    if (_resumeApplied || widget.request.isLive || widget.request.resumeKey == null) return;
    final r = _prefs.resume(widget.request.resumeKey!);
    if (r == null) {
      _resumeApplied = true;
      return;
    }
    final t = (r['t'] as num?)?.toInt() ?? 0;
    final dur = _knownDurSec ?? 0;
    if (t > 15 && (dur == 0 || t < dur - 30)) {
      _resumeApplied = true;
      _player.seek(Duration(seconds: t));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reprise à ${_fmt(t)}'), duration: const Duration(seconds: 3), backgroundColor: KtvColors.panel),
        );
      }
    } else {
      _resumeApplied = true;
    }
  }

  void _maybeMarkWatched() {
    if (_watchedMarked || widget.request.resumeKey == null) return;
    final dur = _knownDurSec ?? 0;
    if (dur > 300 && _position.inSeconds / dur >= 0.9) {
      _watchedMarked = true;
      _prefs.setWatched(widget.request.resumeKey!, true);
      // Scrobble Trakt (films) si connecté ET « marquer vu auto » activé.
      if (widget.request.kind == MediaKind.movie && _trakt.connected && _prefs.settingBool('traktScrobble', true)) {
        _trakt.markMovieWatched(widget.request.title);
      }
    }
  }

  Future<void> _saveResume() async {
    final key = widget.request.resumeKey;
    if (key == null || widget.request.isLive) return;
    final dur = _knownDurSec ?? 0;
    if (_position.inSeconds > 15) {
      await _prefs.saveResume(key, _position.inSeconds, dur);
    }
  }

  String _fmt(int s) {
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, ss = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(ss)}' : '${two(m)}:${two(ss)}';
  }

  void _armHide() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _playing) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _toggleFullscreen() async {
    _fullscreen = !_fullscreen;
    try {
      await windowManager.setFullScreen(_fullscreen);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _seekBy(int secs) {
    final t = _position + Duration(seconds: secs);
    _player.seek(t < Duration.zero ? Duration.zero : t);
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    _armHide();
    switch (e.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
        _player.playOrPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (!widget.request.isLive) _seekBy(10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (!widget.request.isLive) _seekBy(-10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _player.setVolume((((_volume * 100) + 10).clamp(0, 100)));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _player.setVolume((((_volume * 100) - 10).clamp(0, 100)));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyM:
        _player.setVolume(_muted ? _volume * 100 : 0);
        setState(() => _muted = !_muted);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (_fullscreen) {
          _toggleFullscreen();
        } else {
          _close();
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _closing = false;
  // Zapping : change de chaîne sans quitter le lecteur.
  void _switchChannel(LiveChannel ch) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    setState(() {
      _liveId = ch.streamId;
      _title = ch.name;
      _sidebarOpen = false;
    });
    _player.open(Media(urls.live(ch.streamId, ext: 'ts')));
    _prefs.pushRecent(RecentEntry(kind: MediaKind.live, id: ch.streamId, name: ch.name, cover: ch.icon, ext: 'ts', at: DateTime.now().millisecondsSinceEpoch));
  }

  // Démarre/arrête l'enregistrement de la chaîne courante (la lecture continue).
  Future<void> _toggleRecord() async {
    final rec = ref.read(recordingControllerProvider.notifier);
    if (rec.isRecording) {
      await rec.stop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enregistrement arrêté (Réglages → Enregistrements)')));
      return;
    }
    await _record();
  }

  Future<void> _record({int? durationSec, bool compress = true}) async {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null || _liveId == null) return;
    final err = await ref.read(recordingControllerProvider.notifier).start(name: _title, url: urls.live(_liveId!, ext: 'ts'), durationSec: durationSec, compress: compress);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Enregistrement démarré · la lecture continue (Réglages → Enregistrements)')));
    }
  }

  Future<void> _scheduleDialog() async {
    const starts = [(0, 'Maintenant'), (5, '+5 min'), (15, '+15 min'), (30, '+30 min'), (60, '+1 h')];
    const durations = [(30, '30 min'), (60, '1 h'), (120, '2 h'), (150, '2 h 30 (match)'), (180, '3 h')];
    String two(int n) => n.toString().padLeft(2, '0');
    int startMin = 0;
    DateTime? exactStart; // heure précise choisie (prioritaire sur startMin)
    int durMin = 120;
    bool compress = true;
    await showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) {
          DateTime effectiveStart() => exactStart ?? DateTime.now().add(Duration(minutes: startMin));
          final isNow = exactStart == null && startMin == 0;
          String startLabel() => isNow ? 'maintenant' : 'à ${two(effectiveStart().hour)}:${two(effectiveStart().minute)}';

          return AlertDialog(
            backgroundColor: KtvColors.panel,
            title: const Text('Programmer l\'enregistrement'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chaîne : $_title', style: const TextStyle(color: KtvColors.muted, fontSize: 12.5)),
                const SizedBox(height: 14),
                const Text('Début', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in starts)
                    ChoiceChip(
                      label: Text(s.$2),
                      selected: exactStart == null && startMin == s.$1,
                      selectedColor: KtvColors.accent,
                      backgroundColor: KtvColors.panel2,
                      onSelected: (_) => setLocal(() {
                        startMin = s.$1;
                        exactStart = null;
                      }),
                    ),
                  // Heure précise via sélecteur d'horloge.
                  ActionChip(
                    avatar: Icon(Icons.schedule, size: 16, color: exactStart != null ? Colors.white : KtvColors.accent2),
                    label: Text(exactStart == null ? 'Heure précise…' : 'à ${two(exactStart!.hour)}:${two(exactStart!.minute)}'),
                    backgroundColor: exactStart != null ? KtvColors.accent : KtvColors.panel2,
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showTimePicker(context: dctx, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))));
                      if (picked == null) return;
                      var dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                      if (dt.isBefore(now)) dt = dt.add(const Duration(days: 1)); // demain si l'heure est passée
                      setLocal(() => exactStart = dt);
                    },
                  ),
                ]),
                const SizedBox(height: 14),
                const Text('Durée', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final dd in durations)
                    ChoiceChip(
                      label: Text(dd.$2),
                      selected: durMin == dd.$1,
                      selectedColor: KtvColors.accent,
                      backgroundColor: KtvColors.panel2,
                      onSelected: (_) => setLocal(() => durMin = dd.$1),
                    ),
                ]),
                const SizedBox(height: 14),
                const Text('Qualité', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  ChoiceChip(label: const Text('Compact (720p, léger)'), selected: compress, selectedColor: KtvColors.accent, backgroundColor: KtvColors.panel2, onSelected: (_) => setLocal(() => compress = true)),
                  ChoiceChip(label: const Text('Original (lourd)'), selected: !compress, selectedColor: KtvColors.accent, backgroundColor: KtvColors.panel2, onSelected: (_) => setLocal(() => compress = false)),
                ]),
                const SizedBox(height: 14),
                Text('Enregistrera $startLabel() pendant ${durMin >= 60 ? '${durMin ~/ 60} h${durMin % 60 == 0 ? '' : ' ${durMin % 60}'}' : '$durMin min'} · ${compress ? 'compact' : 'original'} (arrêt auto).',
                    style: const TextStyle(color: KtvColors.accent2, fontSize: 12.5)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Annuler')),
              FilledButton.icon(
                icon: const Icon(Icons.fiber_manual_record, size: 16),
                label: Text(isNow ? 'Enregistrer' : 'Programmer'),
                onPressed: () {
                  Navigator.pop(dctx);
                  if (isNow) {
                    _record(durationSec: durMin * 60, compress: compress);
                  } else {
                    _scheduleRecord(effectiveStart(), durMin, compress);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _scheduleRecord(DateTime at, int durMin, bool compress) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null || _liveId == null) return;
    ref.read(recordingControllerProvider.notifier).schedule(
          name: _title,
          url: urls.live(_liveId!, ext: 'ts'),
          at: at,
          durationSec: durMin * 60,
          compress: compress,
        );
    String two(int n) => n.toString().padLeft(2, '0');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Programmé à ${two(at.hour)}:${two(at.minute)} — $_title (Réglages → Enregistrements)')));
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _saveResume();
    try {
      await _player.stop(); // coupe le flux tout de suite (audio + connexion fournisseur)
    } catch (_) {}
    if (_fullscreen) {
      try {
        await windowManager.setFullScreen(false);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _saveResume();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _lock.release(ConnUse.playback);
    // Arrêt + libération : sans le stop explicite, l'audio continuait après le retour.
    try {
      _player.stop();
    } catch (_) {}
    _player.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRec = ref.watch(recordingControllerProvider).any((r) => r.status == RecStatus.recording);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // Retour via geste/clavier système : on stoppe aussi le flux.
        if (didPop) {
          try {
            _player.stop();
          } catch (_) {}
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: MouseRegion(
          onHover: (_) => _armHide(),
          child: Stack(
            children: [
              Positioned.fill(child: Video(controller: _video, controls: NoVideoControls)),
              // Barre du haut : retour + titre
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent]),
                  ),
                  child: Row(
                    children: [
                      IconButton(onPressed: _close, icon: const Icon(Icons.arrow_back, color: Colors.white)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            if (widget.request.subtitle != null)
                              Text(widget.request.subtitle!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isRec) const _RecBadge(),
                      if (widget.request.isLive) ...[
                        IconButton(
                          tooltip: isRec ? 'Arrêter l\'enregistrement' : 'Enregistrer',
                          onPressed: _toggleRecord,
                          icon: Icon(isRec ? Icons.stop_circle : Icons.fiber_manual_record, color: KtvColors.rec),
                        ),
                        IconButton(tooltip: 'Programmer', onPressed: _scheduleDialog, icon: const Icon(Icons.schedule, color: Colors.white)),
                        if (widget.request.liveCategoryId != null)
                          IconButton(tooltip: 'Chaînes', onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen), icon: Icon(Icons.dvr, color: _sidebarOpen ? KtvColors.accent : Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
              // Sidebar de zapping (chaînes de la même catégorie)
              if (_sidebarOpen && widget.request.liveCategoryId != null)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  width: 300,
                  child: _ZapSidebar(
                    categoryId: widget.request.liveCategoryId!,
                    currentId: _liveId,
                    onPick: _switchChannel,
                    onClose: () => setState(() => _sidebarOpen = false),
                  ),
                ),
              // Barre du bas : contrôles
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: PlayerControls(
                    playing: _playing,
                    isLive: widget.request.isLive,
                    position: _position,
                    duration: _effDuration,
                    buffered: _bufferPos,
                    volume: _volume,
                    muted: _muted,
                    audioTracks: _audio,
                    subtitleTracks: _subtitle,
                    currentAudioId: _curAudioId,
                    currentSubtitleId: _curSubId,
                    isFullscreen: _fullscreen,
                    onPlayPause: () => _player.playOrPause(),
                    onSeek: (d) => _player.seek(d),
                    onVolume: (v) {
                      _muted = false;
                      _player.setVolume(v * 100);
                    },
                    onMuteToggle: () {
                      _player.setVolume(_muted ? _volume * 100 : 0);
                      setState(() => _muted = !_muted);
                    },
                    onSelectAudio: (a) => _player.setAudioTrack(a),
                    onSelectSubtitle: (s) => _player.setSubtitleTrack(s),
                    onToggleFullscreen: _toggleFullscreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Pastille « ● REC » affichée pendant un enregistrement.
class _RecBadge extends StatelessWidget {
  const _RecBadge();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: KtvColors.rec, borderRadius: BorderRadius.circular(20)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
          SizedBox(width: 5),
          Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1)),
        ]),
      );
}

/// Panneau latéral de zapping : chaînes de la même catégorie.
class _ZapSidebar extends ConsumerWidget {
  final String categoryId;
  final String? currentId;
  final void Function(LiveChannel) onPick;
  final VoidCallback onClose;
  const _ZapSidebar({required this.categoryId, required this.currentId, required this.onPick, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chans = ref.watch(channelsByCategoryProvider(categoryId)).asData?.value ?? const <LiveChannel>[];
    return Container(
      color: KtvColors.panel.withValues(alpha: 0.96),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Row(children: [
              const Text('Chaînes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClose),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chans.length,
              itemBuilder: (_, i) {
                final ch = chans[i];
                final active = ch.streamId == currentId;
                return ListTile(
                  dense: true,
                  selected: active,
                  selectedTileColor: KtvColors.panel2,
                  leading: (ch.icon != null && ch.icon!.isNotEmpty)
                      ? Image.network(ch.icon!, width: 40, height: 26, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.live_tv, size: 18, color: KtvColors.muted))
                      : const Icon(Icons.live_tv, size: 18, color: KtvColors.muted),
                  title: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: active ? KtvColors.accent2 : KtvColors.txt)),
                  onTap: () => onPick(ch),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
