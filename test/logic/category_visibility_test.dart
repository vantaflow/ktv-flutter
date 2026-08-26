import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/features/categories/category_prefs.dart';
import 'package:ktv/core/models/models.dart';

void main() {
  // Heuristique fictive : autorise les noms commençant par « FR| ».
  bool heuristic(String? name) => (name ?? '').toUpperCase().startsWith('FR|');

  group('categoryVisible', () {
    test('sans override → suit l\'heuristique', () {
      expect(categoryVisible(catId: '1', name: 'FR| TF1', overrides: {}, heuristic: heuristic), isTrue);
      expect(categoryVisible(catId: '2', name: 'AR| MBC', overrides: {}, heuristic: heuristic), isFalse);
    });

    test('override true force l\'affichage même si l\'heuristique masque', () {
      expect(categoryVisible(catId: '2', name: 'AR| MBC', overrides: {'2': true}, heuristic: heuristic), isTrue);
    });

    test('override false force le masquage même si l\'heuristique autorise', () {
      expect(categoryVisible(catId: '1', name: 'FR| TF1', overrides: {'1': false}, heuristic: heuristic), isFalse);
    });

    test('override d\'une autre catégorie n\'affecte pas la courante', () {
      expect(categoryVisible(catId: '1', name: 'FR| TF1', overrides: {'99': false}, heuristic: heuristic), isTrue);
    });
  });

  group('orderCategories', () {
    List<Category> cats(List<String> ids) => [for (final id in ids) Category(id, 'cat$id')];
    List<String> ids(List<Category> cs) => [for (final c in cs) c.id];

    test('ordre vide → liste inchangée', () {
      expect(ids(orderCategories(cats(['1', '2', '3']), const [])), ['1', '2', '3']);
    });

    test('applique l\'ordre demandé', () {
      expect(ids(orderCategories(cats(['1', '2', '3']), ['3', '1', '2'])), ['3', '1', '2']);
    });

    test('ids inconnus restent en fin, ordre d\'origine préservé (stable)', () {
      expect(ids(orderCategories(cats(['1', '2', '3', '4']), ['3'])), ['3', '1', '2', '4']);
    });

    test('ids de l\'ordre absents des catégories sont ignorés', () {
      expect(ids(orderCategories(cats(['1', '2']), ['9', '2', '1'])), ['2', '1']);
    });
  });

  group('CatSectionX', () {
    test('clés de persistance stables', () {
      expect(CatSection.live.key, 'live');
      expect(CatSection.vod.key, 'vod');
      expect(CatSection.series.key, 'series');
    });

    test('libellés', () {
      expect(CatSection.live.label, 'Live TV');
      expect(CatSection.vod.label, 'Films');
      expect(CatSection.series.label, 'Séries');
    });
  });

  group('visibleCategories — garde-fou anti-écran-vide', () {
    final cats = [
      Category('1', 'ARABIC MOVIES'),
      Category('2', 'TOP MOVIES 4K'),
      Category('3', 'ASIA MOVIES'),
    ];

    test('heuristique qui ne matche rien → tout le catalogue est renvoyé', () {
      // Sans ce repli, allVod/allSeries filtrent sur un set vide et jettent
      // 100 % du catalogue : écran Films/Séries vide alors que le réseau a
      // ramené 76 000 films (cas réel, provider cf.youripitv-pro.site).
      expect(visibleCategories(cats: cats, overrides: const {}, heuristic: heuristic).length, 3);
    });

    test('un choix explicite visible → le choix utilisateur prime', () {
      final out = visibleCategories(cats: cats, overrides: const {'2': true}, heuristic: heuristic);
      expect(out.map((c) => c.id), ['2']);
    });

    test('overrides tous à false et heuristique muette → repli, jamais d\'écran vide', () {
      final out = visibleCategories(
        cats: cats,
        overrides: const {'1': false, '2': false, '3': false},
        heuristic: heuristic,
      );
      expect(out.length, 3);
    });

    test('heuristique qui matche → filtrage normal, pas de repli', () {
      final mixed = [...cats, Category('4', 'FR| ACTION')];
      final out = visibleCategories(cats: mixed, overrides: const {}, heuristic: heuristic);
      expect(out.map((c) => c.id), ['4']);
    });

    test('catalogue vide → liste vide (pas de repli fantôme)', () {
      expect(visibleCategories(cats: const [], overrides: const {}, heuristic: heuristic), isEmpty);
    });
  });
}
