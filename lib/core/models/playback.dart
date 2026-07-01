import 'models.dart';

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

  const PlaybackRequest({
    required this.url,
    required this.title,
    this.subtitle,
    required this.kind,
    this.resumeKey,
    this.knownDurationSec,
    this.liveStreamId,
    this.liveCategoryId,
  });

  bool get isLive => kind == MediaKind.live;
}
