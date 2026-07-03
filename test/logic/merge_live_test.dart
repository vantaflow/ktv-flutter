import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/models/models.dart';
import 'package:ktv/core/logic/merge_live.dart';

LiveChannel ch(String id, String name, {String? tvg, String cat = 'FR'}) =>
    LiveChannel(streamId: id, name: name, categoryId: cat, epgChannelId: tvg);

void main() {
  group('dedupKey', () {
    test('tvg-id prioritaire', () => expect(dedupKey(ch('1', 'TF1 HD', tvg: 'tf1.fr')), 'tvg:tf1.fr'));
    test('sinon nom normalisé', () => expect(dedupKey(ch('1', 'TF1 HD!')), 'name:tf1 hd'));
  });

  group('mergedCatId', () {
    test('normalise le nom', () => expect(mergedCatId('FR | Sport'), 'm::fr sport'));
    test('vide → autres', () => expect(mergedCatId(''), 'm::autres'));
  });

  group('mergeLive', () {
    test('dédoublonne par tvg-id entre sources → alts', () {
      final items = <SourcedChannel>[
        (sourceId: 'A', ch: ch('10', 'TF1', tvg: 'tf1.fr'), catName: 'FR'),
        (sourceId: 'B', ch: ch('99', 'TF1 FHD', tvg: 'tf1.fr'), catName: 'FR'),
      ];
      final m = mergeLive(items);
      expect(m.channels.length, 1);
      expect(m.channels.first.sourceId, 'A'); // 1re source = primaire
      expect(m.channels.first.streamId, '10');
      expect(m.channels.first.alts, [(sourceId: 'B', streamId: '99')]);
    });

    test('dédoublonne par nom normalisé si pas de tvg-id', () {
      final items = <SourcedChannel>[
        (sourceId: 'A', ch: ch('1', 'Canal+ HD'), catName: 'FR'),
        (sourceId: 'B', ch: ch('2', 'canal+  hd'), catName: 'FR'),
      ];
      final m = mergeLive(items);
      expect(m.channels.length, 1);
      expect(m.channels.first.alts.single.sourceId, 'B');
    });

    test('chaînes distinctes conservées, catégories fusionnées par nom', () {
      final items = <SourcedChannel>[
        (sourceId: 'A', ch: ch('1', 'TF1', cat: 'FR TNT'), catName: 'FR TNT'),
        (sourceId: 'B', ch: ch('2', 'M6', cat: 'fr  tnt'), catName: 'fr  tnt'),
      ];
      final m = mergeLive(items);
      expect(m.channels.length, 2);
      // Même catégorie fusionnée (nom normalisé identique).
      expect(m.channels.map((c) => c.categoryId).toSet().length, 1);
      expect(m.categories.length, 1);
    });

    test('l\'ordre des sources définit la priorité', () {
      final items = <SourcedChannel>[
        (sourceId: 'B', ch: ch('99', 'TF1', tvg: 'tf1.fr'), catName: 'FR'),
        (sourceId: 'A', ch: ch('10', 'TF1', tvg: 'tf1.fr'), catName: 'FR'),
      ];
      final m = mergeLive(items);
      expect(m.channels.first.sourceId, 'B'); // 1re rencontrée = primaire
    });
  });
}
