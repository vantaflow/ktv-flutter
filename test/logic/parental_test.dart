import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/features/parental/parental.dart';

ParentalConfig cfg({
  bool pinSet = true,
  String mode = 'lock',
  bool autoAdult = true,
  Set<String> cats = const {},
  Set<String> channels = const {},
}) =>
    ParentalConfig(pinSet: pinSet, mode: mode, autoAdult: autoAdult, lockedCats: cats, lockedChannels: channels);

void main() {
  group('ParentalConfig — désactivé sans PIN', () {
    final c = cfg(pinSet: false, cats: {'live::5'}, channels: {'42'});
    test('rien n\'est verrouillé', () {
      expect(c.enabled, isFalse);
      expect(c.categoryLocked('live', '5', 'XXX'), isFalse);
      expect(c.channelLocked('42', name: 'Porn'), isFalse);
    });
  });

  group('categoryLocked', () {
    test('verrou manuel par section+id', () {
      final c = cfg(cats: {'vod::12'});
      expect(c.categoryLocked('vod', '12', 'Films'), isTrue);
      expect(c.categoryLocked('live', '12', 'Films'), isFalse); // section différente
    });
    test('auto-adulte quand activé', () {
      expect(cfg().categoryLocked('live', '9', 'FR | XXX'), isTrue);
      expect(cfg(autoAdult: false).categoryLocked('live', '9', 'FR | XXX'), isFalse);
    });
    test('catégorie normale non verrouillée', () {
      expect(cfg().categoryLocked('live', '9', 'FR | TF1'), isFalse);
    });
  });

  group('channelLocked', () {
    test('verrou manuel de chaîne', () {
      expect(cfg(channels: {'42'}).channelLocked('42', name: 'Une chaîne'), isTrue);
    });
    test('hérite du verrou de sa catégorie', () {
      expect(cfg(cats: {'live::7'}).channelLocked('99', catId: '7', name: 'Une chaîne'), isTrue);
    });
    test('auto-adulte par nom de chaîne', () {
      expect(cfg().channelLocked('99', catId: '1', name: 'Brazzers TV'), isTrue);
      expect(cfg().channelLocked('99', catId: '1', name: 'France 2'), isFalse);
    });
  });

  group('hideMode', () {
    test('reflète le mode', () {
      expect(cfg(mode: 'hide').hideMode, isTrue);
      expect(cfg(mode: 'lock').hideMode, isFalse);
    });
  });
}
