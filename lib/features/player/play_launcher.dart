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

  /// Construit l'URL timeshift Xtream d'un programme passé (réutilisée par la
  /// lecture ET le téléchargement de rediffusion). Renvoie null si pas de profil.
  static String? timeshiftUrl(WidgetRef ref, LiveChannel ch, EpgProgram p) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return null;
    final start = DateTime.fromMillisecondsSinceEpoch(p.start * 1000);
    final durMin = ((p.stop - p.start) / 60).ceil().clamp(1, 600);
    String two(int n) => n.toString().padLeft(2, '0');
    final ymdHi = '${start.year}-${two(start.month)}-${two(start.day)}:${two(start.hour)}-${two(start.minute)}';
    return urls.timeshift(ch.streamId, durMin, ymdHi);
  }

  /// Catch-up / rediffusion : rejoue un programme passé via l'URL timeshift Xtream.
  static void timeshift(BuildContext context, WidgetRef ref, LiveChannel ch, EpgProgram p) {
    final url = timeshiftUrl(ref, ch, p);
    if (url == null) return;
    _open(context, ref, PlaybackRequest(url: url, title: p.title.isEmpty ? ch.name : p.title, subtitle: '${ch.name} · rediffusion', kind: MediaKind.movie));
  }

  /// Lit un fichier local déjà téléchargé (media_kit accepte un chemin de fichier).
  static void localFile(BuildContext context, WidgetRef ref, String name, String path, {String? subtitle}) {
    _open(context, ref, PlaybackRequest(url: path, title: name, subtitle: subtitle, kind: MediaKind.movie));
  }

  static void live(BuildContext context, WidgetRef ref, LiveChannel ch) {
    final urls = ref.read(xtreamUrlsProvider);
    if (urls == null) return;
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: MediaKind.live, id: ch.streamId, name: ch.name, cover: ch.icon, ext: 'ts', categoryId: ch.categoryId, at: _now));
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
    ref.read(prefsProvider).pushRecent(RecentEntry(kind: e.kind, id: e.id, name: e.name, cover: e.cover, ext: e.ext, resumeKey: e.resumeKey, subtitle: e.subtitle, categoryId: e.categoryId, at: _now));
    _open(
      context,
      ref,
      PlaybackRequest(
        url: url,
        title: e.name,
        subtitle: e.subtitle,
        kind: e.kind,
        resumeKey: e.resumeKey,
        // Live lancé depuis l'accueil : on transporte l'id + la catégorie pour que
        // restream / enregistrement / zapping fonctionnent aussi.
        liveStreamId: e.kind == MediaKind.live ? e.id : null,
        liveCategoryId: e.kind == MediaKind.live ? e.categoryId : null,
      ),
    );
  }
}
