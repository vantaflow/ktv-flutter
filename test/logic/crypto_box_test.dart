import 'package:flutter_test/flutter_test.dart';
import 'package:ktv/services/sync/crypto_box.dart';

void main() {
  group('CryptoBox', () {
    test('round-trip : seal puis open avec la bonne phrase', () async {
      const clear = '{"hello":"monde","n":42}';
      final env = await CryptoBox.seal(clear, 'ma-phrase-secrete');
      expect(await CryptoBox.open(env, 'ma-phrase-secrete'), clear);
    });

    test('phrase incorrecte → échec de déchiffrement', () async {
      final env = await CryptoBox.seal('{"x":1}', 'bonne');
      expect(() => CryptoBox.open(env, 'mauvaise'), throwsA(anything));
    });

    test('deux enveloppes du même clair diffèrent (sel + nonce aléatoires)', () async {
      final a = await CryptoBox.seal('{"x":1}', 'p');
      final b = await CryptoBox.seal('{"x":1}', 'p');
      expect(a == b, false);
      // mais les deux se déchiffrent
      expect(await CryptoBox.open(a, 'p'), await CryptoBox.open(b, 'p'));
    });
  });
}
