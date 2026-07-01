import 'dart:convert';

/// Modèles Xtream (parsing tolérant : les champs arrivent en int OU string).
String _s(dynamic v) => v == null ? '' : v.toString();
String? _sn(dynamic v) => v?.toString();

enum MediaKind { live, movie, series }

class XtreamProfile {
  final String id; // srv|usr
  final String label;
  final String srv;
  final String usr;
  final String pwd;
  const XtreamProfile({required this.id, required this.label, required this.srv, required this.usr, required this.pwd});

  factory XtreamProfile.create(String srv, String usr, String pwd, {String? label}) {
    final s = srv.replaceAll(RegExp(r'/+$'), '');
    return XtreamProfile(id: '$s|$usr', label: label ?? Uri.tryParse(s)?.host ?? s, srv: s, usr: usr, pwd: pwd);
  }
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'srv': srv, 'usr': usr, 'pwd': pwd};
  factory XtreamProfile.fromJson(Map<String, dynamic> j) =>
      XtreamProfile(id: _s(j['id']), label: _s(j['label']), srv: _s(j['srv']), usr: _s(j['usr']), pwd: _s(j['pwd']));
}

class Category {
  final String id;
  final String name;
  const Category(this.id, this.name);
  factory Category.fromJson(Map<String, dynamic> j) => Category(_s(j['category_id']), _s(j['category_name']));
}

class LiveChannel {
  final String streamId;
  final String name;
  final String? icon;
  final String categoryId;
  final String? epgChannelId;
  const LiveChannel({required this.streamId, required this.name, this.icon, required this.categoryId, this.epgChannelId});
  factory LiveChannel.fromJson(Map<String, dynamic> j) => LiveChannel(
        streamId: _s(j['stream_id']),
        name: _s(j['name']),
        icon: _sn(j['stream_icon']),
        categoryId: _s(j['category_id']),
        epgChannelId: _sn(j['epg_channel_id']),
      );
}

class VodItem {
  final String streamId;
  final String name;
  final String? cover;
  final String categoryId;
  final String ext;
  final double rating;
  final int added;
  String? tmdbId;
  VodItem({
    required this.streamId,
    required this.name,
    this.cover,
    required this.categoryId,
    required this.ext,
    this.rating = 0,
    this.added = 0,
  });
  factory VodItem.fromJson(Map<String, dynamic> j) => VodItem(
        streamId: _s(j['stream_id']),
        name: _s(j['name']),
        cover: _sn(j['stream_icon']) ?? _sn(j['cover']),
        categoryId: _s(j['category_id']),
        ext: (j['container_extension'] == null || _s(j['container_extension']).isEmpty) ? 'mp4' : _s(j['container_extension']),
        rating: double.tryParse(_s(j['rating'])) ?? 0,
        added: int.tryParse(_s(j['added'])) ?? 0,
      );
}

class SeriesItem {
  final String seriesId;
  final String name;
  final String? cover;
  final String categoryId;
  final double rating;
  final int lastModified;
  String? tmdbId;
  SeriesItem({
    required this.seriesId,
    required this.name,
    this.cover,
    required this.categoryId,
    this.rating = 0,
    this.lastModified = 0,
  });
  factory SeriesItem.fromJson(Map<String, dynamic> j) => SeriesItem(
        seriesId: _s(j['series_id']),
        name: _s(j['name']),
        cover: _sn(j['cover']) ?? _sn(j['stream_icon']),
        categoryId: _s(j['category_id']),
        rating: double.tryParse(_s(j['rating'])) ?? 0,
        lastModified: int.tryParse(_s(j['last_modified'])) ?? 0,
      );
}

class Episode {
  final String id;
  final String title;
  final int episodeNum;
  final String season;
  final String ext;
  final Map<String, dynamic> info;
  const Episode({required this.id, required this.title, required this.episodeNum, required this.season, required this.ext, required this.info});
  factory Episode.fromJson(Map<String, dynamic> j, String season) => Episode(
        id: _s(j['id']),
        title: _s(j['title']),
        episodeNum: int.tryParse(_s(j['episode_num'])) ?? 0,
        season: season,
        ext: (j['container_extension'] == null || _s(j['container_extension']).isEmpty) ? 'mp4' : _s(j['container_extension']),
        info: (j['info'] is Map) ? Map<String, dynamic>.from(j['info']) : const {},
      );
}

/// Entrée d'historique « récent » (rejouable) — persistée en JSON.
class RecentEntry {
  final MediaKind kind;
  final String id; // stream_id (movie/live) ou episode id (series)
  final String name;
  final String? cover;
  final String ext;
  final String? resumeKey;
  final String? subtitle; // ex. « Saison 1 · Épisode 2 »
  final String? categoryId; // catégorie live (pour le zapping/restream depuis l'accueil)
  final int at;
  const RecentEntry({
    required this.kind,
    required this.id,
    required this.name,
    this.cover,
    required this.ext,
    this.resumeKey,
    this.subtitle,
    this.categoryId,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': id,
        'name': name,
        'cover': cover,
        'ext': ext,
        'resumeKey': resumeKey,
        'subtitle': subtitle,
        'categoryId': categoryId,
        'at': at,
      };
  factory RecentEntry.fromJson(Map<String, dynamic> j) => RecentEntry(
        kind: MediaKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => MediaKind.movie),
        id: _s(j['id']),
        name: _s(j['name']),
        cover: _sn(j['cover']),
        ext: _s(j['ext']).isEmpty ? 'mp4' : _s(j['ext']),
        resumeKey: _sn(j['resumeKey']),
        subtitle: _sn(j['subtitle']),
        categoryId: _sn(j['categoryId']),
        at: int.tryParse(_s(j['at'])) ?? 0,
      );
}

/// Programme EPG (get_short_epg) — titres/desc en base64 côté Xtream.
class EpgProgram {
  final String title;
  final String description;
  final int start; // epoch (s)
  final int stop; // epoch (s)
  const EpgProgram({required this.title, required this.description, required this.start, required this.stop});

  static String _b64(dynamic v) {
    final s = (v ?? '').toString();
    if (s.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(s)).trim();
    } catch (_) {
      return s;
    }
  }

  factory EpgProgram.fromJson(Map<String, dynamic> j) => EpgProgram(
        title: _b64(j['title']),
        description: _b64(j['description']),
        start: int.tryParse(_s(j['start_timestamp'])) ?? 0,
        stop: int.tryParse(_s(j['stop_timestamp'])) ?? 0,
      );

  bool get isNow {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return start <= now && (stop == 0 || now < stop);
  }
}

class UserInfo {
  final bool authOk;
  final String status;
  final String expDate; // epoch (s) en chaîne, ou vide
  final int activeCons;
  final int maxCons;
  final bool isTrial;
  final String createdAt; // epoch (s) en chaîne
  final String timezone;
  final String message;
  final List<String> allowedFormats;
  const UserInfo({
    required this.authOk,
    required this.status,
    required this.expDate,
    required this.activeCons,
    required this.maxCons,
    this.isTrial = false,
    this.createdAt = '',
    this.timezone = '',
    this.message = '',
    this.allowedFormats = const [],
  });
  factory UserInfo.fromJson(Map<String, dynamic> j) {
    final ui = (j['user_info'] is Map) ? Map<String, dynamic>.from(j['user_info']) : <String, dynamic>{};
    final si = (j['server_info'] is Map) ? Map<String, dynamic>.from(j['server_info']) : <String, dynamic>{};
    final fmts = (ui['allowed_output_formats'] is List) ? (ui['allowed_output_formats'] as List).map((e) => e.toString()).toList() : <String>[];
    return UserInfo(
      authOk: _s(ui['auth']) == '1',
      status: _s(ui['status']),
      expDate: _s(ui['exp_date']),
      activeCons: int.tryParse(_s(ui['active_cons'])) ?? 0,
      maxCons: int.tryParse(_s(ui['max_connections'])) ?? 0,
      isTrial: _s(ui['is_trial']) == '1',
      createdAt: _s(ui['created_at']),
      timezone: _s(si['timezone']),
      message: _s(ui['message']),
      allowedFormats: fmts,
    );
  }
}
