import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class VoterSearchCrypto {
  VoterSearchCrypto(this._aesKeyUtf8)
    : assert(
        utf8.encode(_aesKeyUtf8).length == 32,
        'AES-256 key must be 32 UTF-8 bytes',
      );

  final String _aesKeyUtf8;
  final AesGcm _aes = AesGcm.with256bits();

  SecretKey get _secretKey => SecretKey(utf8.encode(_aesKeyUtf8));

  Future<String> encrypt(String plain) async {
    final List<int> nonce = _aes.newNonce();
    final SecretBox box = await _aes.encrypt(
      utf8.encode(plain),
      secretKey: _secretKey,
      nonce: nonce,
    );
    final Uint8List out = Uint8List(
      box.nonce.length + box.mac.bytes.length + box.cipherText.length,
    );
    var offset = 0;
    out.setAll(offset, box.nonce);
    offset += box.nonce.length;
    out.setAll(offset, box.mac.bytes);
    offset += box.mac.bytes.length;
    out.setAll(offset, box.cipherText);
    return base64Encode(out);
  }

  Future<Uint8List> decryptToBytes(String cipherB64) async {
    final Uint8List raw = base64Decode(cipherB64);
    if (raw.length < 28) {
      throw const FormatException('Ciphertext too short for AES-GCM');
    }
    final List<int> nonce = raw.sublist(0, 12);
    final Mac mac = Mac(raw.sublist(12, 28));
    final List<int> cipherText = raw.sublist(28);
    final List<int> clear = await _aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: _secretKey,
    );
    return Uint8List.fromList(clear);
  }

  Future<String> decrypt(String cipherB64) async {
    return utf8.decode(await decryptToBytes(cipherB64));
  }

  Future<String> decryptDataField(String data) async {
    final String trimmed = data.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return trimmed;
    }
    return decrypt(trimmed);
  }

  Future<Uint8List> resolvePhotoPayload(String data) async {
    final String trimmed = data.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty photo data');
    }
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return Uint8List.fromList(utf8.encode(trimmed));
    }
    try {
      return await decryptToBytes(trimmed);
    } catch (_) {
      return Uint8List.fromList(utf8.encode(trimmed));
    }
  }
}
