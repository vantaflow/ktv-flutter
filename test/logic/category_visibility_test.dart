import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/features/categories/category_prefs.dart';

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
}
