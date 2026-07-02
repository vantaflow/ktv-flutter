/// Fusion des bundles de synchronisation (logique pure, testée).
///
/// Un « bundle » est une Map { cléPref: valeurJSONdécodée } couvrant les clés
/// de [PrefsStore.syncKeys]. La fusion combine l'état local et l'état distant :
///  - maps horodatées (reprise / vu / récent) : fusion fine par timestamp ;
///  - favoris : union par id ;
///  - le reste (réglages, catégories, profils) : dernier écrivain gagne au
///    niveau du groupe (piloté par [remoteNewer]).
library;

Map<String, dynamic> _asMap(Object? v) => v is Map ? Map<String, dynamic>.from(v) : {};
List _asList(Object? v) => v is List ? List.from(v) : [];

int _num(Object? v) => v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? 0);

/// Reprise : { key: {t,d,at} } → on garde l'entrée au `at` le plus récent.
Map<String, dynamic> mergeResume(Object? local, Object? remote) {
  final out = _asMap(local);
  final r = _asMap(remote);
  r.forEach((k, v) {
    final cur = out[k];
    if (cur == null || _num(_asMap(v)['at']) > _num(_asMap(cur)['at'])) out[k] = v;
  });
  return out;
}

/// Vu : { key: ts } → on garde le ts le plus récent.
Map<String, dynamic> mergeWatched(Object? local, Object? remote) {
  final out = _asMap(local);
  _asMap(remote).forEach((k, v) {
    if (_num(v) > _num(out[k])) out[k] = v;
  });
  return out;
}

/// Favoris : liste de {id,…} → union par id (l'entrée locale prime sur le doublon).
List mergeFavs(Object? local, Object? remote) {
  final out = _asList(local);
  final ids = {for (final e in out) '${_asMap(e)['id']}'};
  for (final e in _asList(remote)) {
    final id = '${_asMap(e)['id']}';
    if (!ids.contains(id)) {
      out.add(e);
      ids.add(id);
    }
  }
  return out;
}

/// Récent : liste d'entrées {kind,id,at} → fusion par (kind,id) au `at` le plus
/// récent, tri décroissant, plafonné à 100.
List mergeRecent(Object? local, Object? remote) {
  final byKey = <String, Map<String, dynamic>>{};
  void add(Object? e) {
    final m = _asMap(e);
    final key = '${m['kind']}:${m['id']}';
    final cur = byKey[key];
    if (cur == null || _num(m['at']) > _num(cur['at'])) byKey[key] = m;
  }

  for (final e in _asList(local)) {
    add(e);
  }
  for (final e in _asList(remote)) {
    add(e);
  }
  final list = byKey.values.toList()..sort((a, b) => _num(b['at']).compareTo(_num(a['at'])));
  return list.take(100).toList();
}

/// Fusionne un bundle local et un bundle distant.
/// [remoteNewer] : le bundle distant est plus récent que le dernier connu
/// localement → adopter ses groupes non horodatés (réglages, catégories, profils).
Map<String, dynamic> mergeBundle(Map<String, dynamic> local, Map<String, dynamic> remote, {required bool remoteNewer}) {
  final out = Map<String, dynamic>.from(local);
  out['ktv_resume'] = mergeResume(local['ktv_resume'], remote['ktv_resume']);
  out['iptv_watched'] = mergeWatched(local['iptv_watched'], remote['iptv_watched']);
  out['iptv_favs_v2'] = mergeFavs(local['iptv_favs_v2'], remote['iptv_favs_v2']);
  out['iptv_recent'] = mergeRecent(local['iptv_recent'], remote['iptv_recent']);

  // Groupes sans horodatage fin : dernier écrivain gagne.
  const lww = ['ktv_settings', 'category_visibility', 'category_order', 'xtream_profiles', 'xtream_active'];
  for (final k in lww) {
    if (remoteNewer && remote.containsKey(k)) {
      out[k] = remote[k];
    } else if (!out.containsKey(k) && remote.containsKey(k)) {
      out[k] = remote[k];
    }
  }
  return out;
}
