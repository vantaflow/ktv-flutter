import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Persistance légère (miroir du localStorage KTV) via SharedPreferences + JSON.
/// Un seul point d'accès, injecté par Riverpod.
class PrefsStore {
  final SharedPreferences _p;
  PrefsStore(this._p);

  static Future<PrefsStore> create() async => PrefsStore(await SharedPreferences.getInstance());

  // --- Profils Xtream ---
  static const _kProfiles = 'xtream_profiles';
  static const _kActive = 'xtream_active';

  List<XtreamProfile> profiles() {
    final raw = _p.getString(_kProfiles);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => XtreamProfile.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfiles(List<XtreamProfile> list) =>
      _p.setString(_kProfiles, jsonEncode(list.map((e) => e.toJson()).toList()));

  Future<void> upsertProfile(XtreamProfile prof) async {
    final list = profiles();
    final i = list.indexWhere((e) => e.id == prof.id);
    if (i >= 0) {
      list[i] = prof;
    } else {
      list.add(prof);
    }
    await saveProfiles(list);
  }

  Future<void> removeProfile(String id) async {
    final list = profiles()..removeWhere((e) => e.id == id);
    await saveProfiles(list);
    if (activeId() == id) await _p.remove(_kActive);
  }

  String? activeId() => _p.getString(_kActive);
  Future<void> setActive(String? id) => id == null ? _p.remove(_kActive) : _p.setString(_kActive, id);
  XtreamProfile? activeProfile() {
    final id = activeId();
    if (id == null) return null;
    for (final p in profiles()) {
      if (p.id == id) return p;
    }
    return null;
  }

  // --- Générique JSON map (resume / watched / favorites) ---
  Map<String, dynamic> _map(String key) {
    final raw = _p.getString(key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMap(String key, Map<String, dynamic> m) => _p.setString(key, jsonEncode(m));

  // Resume : { key: {t, d, at} }
  Map<String, dynamic> resumeMap() => _map('ktv_resume');
  Map<String, dynamic>? resume(String key) {
    final r = resumeMap()[key];
    return r is Map ? Map<String, dynamic>.from(r) : null;
  }

  Future<void> saveResume(String key, int t, int d) async {
    final m = resumeMap();
    if (t < 15 || (d > 0 && t / d > 0.99)) {
      m.remove(key);
    } else {
      m[key] = {'t': t, 'd': d, 'at': DateTime.now().millisecondsSinceEpoch};
    }
    await _saveMap('ktv_resume', m);
  }

  Future<void> clearResume(String key) async {
    final m = resumeMap()..remove(key);
    await _saveMap('ktv_resume', m);
  }

  // Watched : { 'movie:id'|'series:epId'|'serieswatched:id': ts }
  Map<String, dynamic> watchedMap() => _map('iptv_watched');
  bool isWatched(String key) => watchedMap().containsKey(key);
  Future<void> setWatched(String key, bool on) async {
    final m = watchedMap();
    if (on) {
      m[key] = DateTime.now().millisecondsSinceEpoch;
    } else {
      m.remove(key);
    }
    await _saveMap('iptv_watched', m);
  }

  // Favoris live : entrées enrichies {id,name,cover} pour affichage direct.
  static const _kFavs = 'iptv_favs_v2';
  List<Map<String, dynamic>> favChannels() {
    final raw = _p.getString(_kFavs);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  bool isFav(String id) => favChannels().any((e) => e['id'] == id);

  Future<void> toggleFav({required String id, required String name, String? cover}) async {
    final list = favChannels();
    final i = list.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.add({'id': id, 'name': name, 'cover': cover});
    }
    await _p.setString(_kFavs, jsonEncode(list));
  }

  // Historique « récent » (rejouable), plafonné à 100, plus récent d'abord.
  static const _kRecent = 'iptv_recent';
  List<RecentEntry> recent() {
    final raw = _p.getString(_kRecent);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => RecentEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> pushRecent(RecentEntry e) async {
    final list = recent()..removeWhere((x) => x.kind == e.kind && x.id == e.id);
    list.insert(0, e);
    final capped = list.take(100).toList();
    await _p.setString(_kRecent, jsonEncode(capped.map((x) => x.toJson()).toList()));
  }

  Future<void> clearRecent() => _p.remove(_kRecent);

  // Cache TMDB (TTL 30 j) : { key: {at, v} }.
  static const _kTmdb = 'tmdb_cache';
  Object? tmdbCacheGet(String key) {
    final m = _map(_kTmdb);
    final e = m[key];
    if (e is Map && e['at'] is num && DateTime.now().millisecondsSinceEpoch - (e['at'] as num) < 30 * 86400000) {
      return e['v'];
    }
    return _sentinelMissing;
  }

  static final Object _sentinelMissing = Object();
  static Object get sentinelMissing => _sentinelMissing;

  Future<void> tmdbCacheSet(String key, Object? value) async {
    final m = _map(_kTmdb);
    m[key] = {'at': DateTime.now().millisecondsSinceEpoch, 'v': value};
    if (m.length > 1200) m.remove(m.keys.first);
    await _saveMap(_kTmdb, m);
  }

  // Réglages applicatifs (ktv_settings) : bufferProfile, tmdbKey, traktClientId…
  static const _kSettings = 'ktv_settings';
  Map<String, dynamic> settings() => _map(_kSettings);
  String settingStr(String key, [String def = '']) {
    final v = settings()[key];
    return v == null ? def : v.toString();
  }

  bool settingBool(String key, [bool def = false]) {
    final v = settings()[key];
    return v is bool ? v : def;
  }

  Future<void> setSetting(String key, Object? value) async {
    final m = settings();
    if (value == null) {
      m.remove(key);
    } else {
      m[key] = value;
    }
    await _saveMap(_kSettings, m);
  }

  // Jeton Trakt (ktv_trakt).
  Map<String, dynamic>? traktToken() {
    final m = _map('ktv_trakt');
    return m.isEmpty ? null : m;
  }

  Future<void> setTraktToken(Map<String, dynamic>? tok) async {
    if (tok == null) {
      await _p.remove('ktv_trakt');
    } else {
      await _saveMap('ktv_trakt', tok);
    }
  }

  bool get traktConnected => (traktToken()?['access_token'] ?? '').toString().isNotEmpty;
}
