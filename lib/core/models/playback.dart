import 'models.dart';

/// Un élément de playlist (épisode) pour l'enchaînement automatique.
class PlaybackItem {
  final String url;
  final String title;
  final String? subtitle; // « Saison 1 · Épisode 2 »
  final String resumeKey; // 'series:epId'
  final int? knownDurationSec;
  final String id; // episode id (pour l'historique)
  final String? cover;
  final String ext;
  const PlaybackItem({
    required this.url,
    required this.title,
    this.subtitle,
    required this.resumeKey,
    this.knownDurationSec,
    required this.id,
    this.cover,
    required this.ext,
  });
}

/// Décrit ce qu'on demande au lecteur (URL déjà construite + métadonnées).
class PlaybackRequest {
  final String url;
  final String title;
  final String? subtitle; // ex. « Saison 1 · Épisode 2 »
  final MediaKind kind;
  final String? resumeKey; // 'movie:id' / 'series:epId' — null pour le live
  final int? knownDurationSec; // durée fiable (API) si connue
  final String? liveStreamId; // pour le zapping + l'enregistrement (live)
  final String? liveCategoryId; // pour la sidebar de zapping (live)
  final List<PlaybackItem>? playlist; // épisodes de la saison (autoplay suivant)
  final int playlistIndex; // position courante dans la playlist

  const PlaybackRequest({
    required this.url,
    required this.title,
    this.subtitle,
    required this.kind,
    this.resumeKey,
    this.knownDurationSec,
    this.liveStreamId,
    this.liveCategoryId,
    this.playlist,
    this.playlistIndex = 0,
  });

  bool get isLive => kind == MediaKind.live;
}
