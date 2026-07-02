import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Chiffrement du bundle de synchronisation côté client.
/// Enveloppe JSON : { v, salt, nonce, ct } (tout en base64). La clé est dérivée
/// de la phrase secrète via PBKDF2-HMAC-SHA256, puis AES-GCM 256 bits.
/// Le serveur ne voit jamais que cette enveloppe — jamais la phrase ni la clé.
class CryptoBox {
  static final _pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 120000, bits: 256);
  static final _aes = AesGcm.with256bits();

  static Future<SecretKey> _deriveKey(String passphrase, List<int> salt) =>
      _pbkdf2.deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);

  /// Chiffre [plaintext] (JSON) → enveloppe base64. [salt] réutilisé s'il est
  /// fourni (pour garder la même clé entre appareils), sinon généré.
  static Future<String> seal(String plaintext, String passphrase, {List<int>? salt}) async {
    final s = salt ?? _aes.newNonce(); // 12 octets aléatoires, suffisant comme sel
    final key = await _deriveKey(passphrase, s);
    final nonce = _aes.newNonce();
    final box = await _aes.encrypt(utf8.encode(plaintext), secretKey: key, nonce: nonce);
    return jsonEncode({
      'v': 1,
      'salt': base64.encode(s),
      'nonce': base64.encode(nonce),
      'ct': base64.encode(box.concatenation(nonce: false)), // ciphertext + tag
    });
  }

  /// Déchiffre une enveloppe base64 → JSON en clair. Lève si la phrase est fausse.
  static Future<String> open(String envelope, String passphrase) async {
    final j = Map<String, dynamic>.from(jsonDecode(envelope));
    final salt = base64.decode(j['salt'] as String);
    final nonce = base64.decode(j['nonce'] as String);
    final ctTag = base64.decode(j['ct'] as String);
    final key = await _deriveKey(passphrase, salt);
    const tagLen = 16;
    final cipherText = Uint8List.sublistView(ctTag, 0, ctTag.length - tagLen);
    final mac = Mac(ctTag.sublist(ctTag.length - tagLen));
    final clear = await _aes.decrypt(SecretBox(cipherText, nonce: nonce, mac: mac), secretKey: key);
    return utf8.decode(clear);
  }

  /// Sel stocké dans une enveloppe existante (pour réutiliser la même clé).
  static List<int>? saltOf(String? envelope) {
    if (envelope == null) return null;
    try {
      return base64.decode(Map<String, dynamic>.from(jsonDecode(envelope))['salt'] as String);
    } catch (_) {
      return null;
    }
  }
}
