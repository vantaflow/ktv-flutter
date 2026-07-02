import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/services/sync/sync_merge.dart';

void main() {
  group('mergeResume', () {
    test('garde l\'entrée au at le plus récent', () {
      final local = {'movie:1': {'t': 100, 'd': 500, 'at': 10}};
      final remote = {'movie:1': {'t': 300, 'd': 500, 'at': 20}, 'movie:2': {'t': 5, 'd': 90, 'at': 30}};
      final m = mergeResume(local, remote);
      expect((m['movie:1'] as Map)['t'], 300); // remote plus récent
      expect(m.containsKey('movie:2'), true);
    });
    test('conserve le local si plus récent', () {
      final local = {'movie:1': {'t': 400, 'd': 500, 'at': 99}};
      final remote = {'movie:1': {'t': 10, 'd': 500, 'at': 20}};
      expect((mergeResume(local, remote)['movie:1'] as Map)['t'], 400);
    });
  });

  group('mergeWatched', () {
    test('garde le ts max', () {
      expect(mergeWatched({'a': 5}, {'a': 9, 'b': 3}), {'a': 9, 'b': 3});
      expect(mergeWatched({'a': 50}, {'a': 9}), {'a': 50});
    });
  });

  group('mergeFavs', () {
    test('union par id, local prioritaire', () {
      final local = [{'id': '1', 'name': 'A'}];
      final remote = [{'id': '1', 'name': 'A2'}, {'id': '2', 'name': 'B'}];
      final m = mergeFavs(local, remote);
      expect(m.length, 2);
      expect((m.firstWhere((e) => e['id'] == '1'))['name'], 'A'); // local gardé
    });
  });

  group('mergeRecent', () {
    test('dédup par (kind,id) au at max, tri desc, cap 100', () {
      final local = [{'kind': 'movie', 'id': '1', 'at': 10}];
      final remote = [{'kind': 'movie', 'id': '1', 'at': 40}, {'kind': 'live', 'id': '9', 'at': 30}];
      final m = mergeRecent(local, remote);
      expect(m.length, 2);
      expect(m.first['at'], 40); // plus récent en tête
    });
  });

  group('mergeBundle', () {
    test('groupes non horodatés : remote adopté si remoteNewer', () {
      final local = {'ktv_settings': {'accentColor': 'orange'}};
      final remote = {'ktv_settings': {'accentColor': 'blue'}};
      expect((mergeBundle(local, remote, remoteNewer: true)['ktv_settings'] as Map)['accentColor'], 'blue');
      expect((mergeBundle(local, remote, remoteNewer: false)['ktv_settings'] as Map)['accentColor'], 'orange');
    });
    test('adopte le groupe distant absent en local même si pas remoteNewer', () {
      final local = <String, dynamic>{};
      final remote = {'xtream_profiles': [{'id': 'x'}]};
      expect(mergeBundle(local, remote, remoteNewer: false)['xtream_profiles'], isNotNull);
    });
  });
}
