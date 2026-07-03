import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/core/logic/text_utils.dart';

void main() {
  group('categoryAllowed', () {
    test('allows FR| prefixed', () => expect(categoryAllowed('FR|TF1'), isTrue));
    test('allows Morocco', () {
      expect(categoryAllowed('MOROCCO CHANNELS'), isTrue);
      expect(categoryAllowed('المغرب'), isTrue);
    });
    test('beIN Sports Arabic yes, Turkish no', () {
      expect(categoryAllowed('AR|BEIN SPORTS 1'), isTrue);
      expect(categoryAllowed('TR|BEIN SPORTS 1'), isFalse);
    });
    test('rejects unrelated', () => expect(categoryAllowed('UK|SPORTS'), isFalse));
  });

  group('frCategoryAllowed', () {
    test('French-named allowed', () {
      expect(frCategoryAllowed('FR| FILMS'), isTrue);
      expect(frCategoryAllowed('FR'), isTrue);
      expect(frCategoryAllowed('VOSTFR'), isTrue);
      expect(frCategoryAllowed('TRUEFRENCH'), isTrue);
    });
    test('rejects non-French', () => expect(frCategoryAllowed('EN|MOVIES'), isFalse));
  });

  group('isJunkChannel', () {
    test('empty', () => expect(isJunkChannel(''), isTrue));
    test('separators', () {
      expect(isJunkChannel('### SECTION ###'), isTrue);
      expect(isJunkChannel('=== TITLE ==='), isTrue);
      expect(isJunkChannel('●●●●●'), isTrue);
    });
    test('real channel', () => expect(isJunkChannel('TF1 HD'), isFalse));
  });

  group('yearOf', () {
    test('extracts', () => expect(yearOf('Inception (2010) 1080p'), '2010'));
    test('none', () => expect(yearOf('No Year Here'), ''));
  });

  group('cleanTitle', () {
    test('strips tags/brackets/prefixes', () {
      expect(cleanTitle('4K-FR - Inception (2010) [MULTI] [1080p]'), 'Inception');
    });
    test('strips superscripts', () => expect(cleanTitle('Le Parrain ᴴᴰ'), 'Le Parrain'));
    test('falls back to trimmed original', () => expect(cleanTitle('   '), ''));
  });

  group('ktvNormTitle', () {
    test('accents/case/punctuation', () => expect(ktvNormTitle('Café de Paris!'), 'cafe de paris'));
    test('empty', () => expect(ktvNormTitle(''), ''));
  });

  group('isAdultCategory', () {
    test('detects explicit adult markers', () {
      expect(isAdultCategory('XXX FR'), isTrue);
      expect(isAdultCategory('FR | ADULTES 18+'), isTrue);
      expect(isAdultCategory('Porn HD'), isTrue);
      expect(isAdultCategory('Érotique'), isTrue); // accents ignorés
      expect(isAdultCategory('Brazzers'), isTrue);
    });
    test('rejects normal categories', () {
      expect(isAdultCategory('FR| TF1'), isFalse);
      expect(isAdultCategory('Documentaires'), isFalse);
      expect(isAdultCategory('Sports'), isFalse);
      expect(isAdultCategory(null), isFalse);
      expect(isAdultCategory(''), isFalse);
    });
  });
}
