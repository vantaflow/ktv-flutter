import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/logic/format.dart';

/// Barre de contrôle custom du lecteur (UI pure). Pilotée par le PlayerScreen.
class PlayerControls extends StatelessWidget {
  final bool playing;
  final bool isLive;
  final Duration position;
  final Duration? duration; // null = inconnue → temps écoulé seul
  final Duration buffered;
  final double volume; // 0..1
  final bool muted;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;
  final String? currentAudioId;
  final String? currentSubtitleId;
  final bool isFullscreen;

  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolume;
  final VoidCallback onMuteToggle;
  final ValueChanged<AudioTrack> onSelectAudio;
  final ValueChanged<SubtitleTrack> onSelectSubtitle;
  final VoidCallback onToggleFullscreen;

  const PlayerControls({
    super.key,
    required this.playing,
    required this.isLive,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.volume,
    required this.muted,
    required this.audioTracks,
    required this.subtitleTracks,
    required this.currentAudioId,
    required this.currentSubtitleId,
    required this.isFullscreen,
    required this.onPlayPause,
    required this.onSeek,
    required this.onVolume,
    required this.onMuteToggle,
    required this.onSelectAudio,
    required this.onSelectSubtitle,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final durMs = duration?.inMilliseconds ?? 0;
    final frac = durMs == 0 ? 0.0 : (position.inMilliseconds / durMs).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPlayPause,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 8),
          if (isLive)
            const Row(children: [
              Icon(Icons.circle, color: KtvColors.rec, size: 10),
              SizedBox(width: 6),
              Text('Direct', style: TextStyle(color: KtvColors.rec, fontWeight: FontWeight.w700)),
            ])
          else ...[
            Text(fmtClock(position.inSeconds), style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 10),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: KtvColors.accent,
                  inactiveTrackColor: Colors.white24,
                  secondaryActiveTrackColor: Colors.white38,
                  thumbColor: KtvColors.accent2,
                ),
                child: Slider(
                  value: frac,
                  secondaryTrackValue: durMs == 0 ? null : (buffered.inMilliseconds / durMs).clamp(0.0, 1.0),
                  onChanged: durMs == 0 ? null : (v) => onSeek(Duration(milliseconds: (v * durMs).round())),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(duration == null ? '--:--' : fmtClock(duration!.inSeconds),
                style: const TextStyle(color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
          ],
          const SizedBox(width: 8),
          if (audioTracks.length > 2)
            _menu<AudioTrack>(
              icon: Icons.volume_up,
              tooltip: 'Piste audio',
              items: audioTracks,
              currentId: currentAudioId,
              labelOf: (a) => _trackLabel(a.id, a.title, a.language),
              idOf: (a) => a.id,
              onSelect: onSelectAudio,
            ),
          if (subtitleTracks.length > 1)
            _menu<SubtitleTrack>(
              icon: Icons.subtitles,
              tooltip: 'Sous-titres',
              items: subtitleTracks,
              currentId: currentSubtitleId,
              labelOf: (s) => _trackLabel(s.id, s.title, s.language),
              idOf: (s) => s.id,
              onSelect: onSelectSubtitle,
            ),
          IconButton(
            onPressed: onMuteToggle,
            icon: Icon(muted || volume == 0 ? Icons.volume_off : Icons.volume_up, color: Colors.white),
          ),
          SizedBox(
            width: 90,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: KtvColors.accent,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(value: muted ? 0 : volume, onChanged: onVolume),
            ),
          ),
          IconButton(
            onPressed: onToggleFullscreen,
            icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _trackLabel(String id, String? title, String? language) {
    if (id == 'auto') return 'Auto';
    if (id == 'no') return 'Désactivé';
    final parts = [language, title].where((e) => e != null && e.isNotEmpty).toList();
    return parts.isEmpty ? 'Piste $id' : parts.join(' · ');
  }

  Widget _menu<T>({
    required IconData icon,
    required String tooltip,
    required List<T> items,
    required String? currentId,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required ValueChanged<T> onSelect,
  }) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: Icon(icon, color: Colors.white),
      color: KtvColors.panel,
      onSelected: onSelect,
      itemBuilder: (_) => items
          .map((t) => PopupMenuItem<T>(
                value: t,
                child: Row(
                  children: [
                    Icon(idOf(t) == currentId ? Icons.check : Icons.circle_outlined,
                        size: 16, color: idOf(t) == currentId ? KtvColors.accent : KtvColors.muted),
                    const SizedBox(width: 8),
                    Flexible(child: Text(labelOf(t), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
