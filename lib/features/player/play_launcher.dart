import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/models/playback.dart';
import '../../core/logic/duration_parse.dart';
import '../../core/providers.dart';
import '../auth/auth_controller.dart';
import 'player_screen.dart';

/// Point d'entrée unique de la lecture : construit l'URL, historise (recent),
/// puis ouvre le lecteur. Réutilisé par Films/Séries/Live ET les rails d'accueil.
class PlayLauncher {
  static int get _now => DateTime.now().millisecondsSinceEpoch;

  static void _open(BuildContext context, WidgetRef ref, PlaybackRequest req) {
    ref.read(recentTickProvider.notifier).state++; // rafraîchit l'accueil
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(request: req)));
  }

  static void movie(BuildContext context, WidgetRef ref, VodItem m) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final key = 'movie:${m.streamId}';
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: MediaKind.movie, id: m.streamId, name: m.name, cover: m.cover, ext: m.ext, resumeKey: key, at: _now));
    _open(context, ref, PlaybackRequest(url: urls.movie(m.streamId, m.ext), title: m.name, kind: MediaKind.movie, resumeKey: key));
  }

  static void episode(BuildContext context, WidgetRef ref, SeriesItem s, Episode ep, {int? durationSec, List<Episode>? seasonEps}) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final key = 'series:${ep.id}';
    final sub = 'Saison ${ep.season} · Épisode ${ep.episodeNum}';
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: MediaKind.series, id: ep.id, name: s.name, cover: s.cover, ext: ep.ext, resumeKey: key, subtitle: sub, at: _now));

    // Playlist de la saison pour l'enchaînement automatique.
    List<PlaybackItem>? playlist;
    var index = 0;
    if (seasonEps != null && seasonEps.isNotEmpty) {
      playlist = [
        for (final e in seasonEps)
          PlaybackItem(
            url: urls.series(e.id, e.ext),
            title: s.name,
            subtitle: 'Saison ${e.season} · Épisode ${e.episodeNum}',
            resumeKey: 'series:${e.id}',
            knownDurationSec: parseXtreamDuration(e.info),
            id: e.id,
            cover: s.cover,
            ext: e.ext,
          ),
      ];
      index = seasonEps.indexWhere((e) => e.id == ep.id);
      if (index < 0) index = 0;
    }

    _open(context, ref, PlaybackRequest(url: urls.series(ep.id, ep.ext), title: s.name, subtitle: sub, kind: MediaKind.series, resumeKey: key, knownDurationSec: durationSec, playlist: playlist, playlistIndex: index));
  }

  static void live(BuildContext context, WidgetRef ref, LiveChannel ch) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: MediaKind.live, id: ch.streamId, name: ch.name, cover: ch.icon, ext: 'ts', at: _now));
    _open(context, ref, PlaybackRequest(url: urls.live(ch.streamId), title: ch.name, kind: MediaKind.live, liveStreamId: ch.streamId, liveCategoryId: ch.categoryId));
  }

  /// Rejoue une entrée d'historique depuis l'accueil.
  static void recent(BuildContext context, WidgetRef ref, RecentEntry e) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    final String url;
    switch (e.kind) {
      case MediaKind.movie:
        url = urls.movie(e.id, e.ext);
        break;
      case MediaKind.series:
        url = urls.series(e.id, e.ext);
        break;
      case MediaKind.live:
        url = urls.live(e.id);
        break;
    }
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: e.kind, id: e.id, name: e.name, cover: e.cover, ext: e.ext, resumeKey: e.resumeKey, subtitle: e.subtitle, at: _now));
    _open(context, ref, PlaybackRequest(url: url, title: e.name, subtitle: e.subtitle, kind: e.kind, resumeKey: e.resumeKey));
  }
}
