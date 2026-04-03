import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatEncryptionService {
  static final ChatEncryptionService _instance = ChatEncryptionService._internal();
  factory ChatEncryptionService() => _instance;
  ChatEncryptionService._internal();

  enc.Key? _key;

  void _ensureInitialized() {
    if (_key != null) return;
    final rawKey = dotenv.env['CHAT_ENCRYPTION_KEY'];
    if (rawKey == null || rawKey.length != 32) {
      throw StateError(
        'CHAT_ENCRYPTION_KEY deve essere esattamente 32 caratteri nel file .env',
      );
    }
    _key = enc.Key.fromUtf8(rawKey);
  }

  /// Cifra un testo in chiaro con AES-256-CBC.
  /// Ritorna una record con ciphertext (base64) e iv (base64).
  ({String ciphertext, String iv}) encryptMessage(String plaintext) {
    _ensureInitialized();
    final ivBytes = _generateRandomIV();
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return (
      ciphertext: encrypted.base64,
      iv: iv.base64,
    );
  }

  /// Decifra un ciphertext base64 usando l'IV base64 fornito.
  String decryptMessage(String ciphertext, String ivBase64) {
    _ensureInitialized();
    try {
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(ciphertext, iv: iv);
    } catch (e) {
      debugPrint('Errore decifratura messaggio: $e');
      return '[messaggio non leggibile]';
    }
  }

  Uint8List _generateRandomIV() {
    final rand = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => rand.nextInt(256)));
  }
}
