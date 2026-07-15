import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 生成 RSA-2048 密钥对，公钥输出为 X.509 DER 的标准 Base64（无换行）。
class RsaKeyPairHelper {
  const RsaKeyPairHelper._();

  static RsaGeneratedKeyPair generate() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    secureRandom.seed(KeyParameter(seed));

    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          secureRandom,
        ),
      );

    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey;
    final privateKey = pair.privateKey;

    return RsaGeneratedKeyPair(
      publicKeyBase64: base64Encode(_encodePublicKeyToX509(publicKey)),
      privateKeyBase64: base64Encode(_encodePrivateKeyToPkcs8(privateKey)),
    );
  }

  /// 使用 PKCS#8 私钥对 UTF-8 消息做 SHA256withRSA，返回 Base64 签名。
  static String signSha256Base64({
    required String privateKeyBase64,
    required String message,
  }) {
    final privateKey = parsePkcs8PrivateKey(privateKeyBase64);
    final signer = Signer('SHA-256/RSA')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(Uint8List.fromList(utf8.encode(message)))
        as RSASignature;
    return base64Encode(sig.bytes);
  }

  static RSAPrivateKey parsePkcs8PrivateKey(String privateKeyBase64) {
    final der = base64Decode(privateKeyBase64);
    final top = _Asn1Reader(der).readNode();
    if (top.tag != 0x30 || top.children.length < 3) {
      throw FormatException('Invalid PKCS#8 private key');
    }
    final octet = top.children[2];
    if (octet.tag != 0x04) {
      throw FormatException('Invalid PKCS#8 private key octet');
    }
    final rsaSeq = _Asn1Reader(octet.content).readNode();
    if (rsaSeq.tag != 0x30 || rsaSeq.children.length < 9) {
      throw FormatException('Invalid RSAPrivateKey');
    }
    // version, n, e, d, p, q, dP, dQ, qInv
    final n = _asn1IntegerValue(rsaSeq.children[1]);
    final e = _asn1IntegerValue(rsaSeq.children[2]);
    final d = _asn1IntegerValue(rsaSeq.children[3]);
    final p = _asn1IntegerValue(rsaSeq.children[4]);
    final q = _asn1IntegerValue(rsaSeq.children[5]);
    return RSAPrivateKey(n, d, p, q, e);
  }
}

class RsaGeneratedKeyPair {
  const RsaGeneratedKeyPair({
    required this.publicKeyBase64,
    required this.privateKeyBase64,
  });

  final String publicKeyBase64;
  final String privateKeyBase64;
}

class _Asn1Node {
  const _Asn1Node({
    required this.tag,
    required this.content,
    this.children = const [],
  });

  final int tag;
  final Uint8List content;
  final List<_Asn1Node> children;
}

class _Asn1Reader {
  _Asn1Reader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  _Asn1Node readNode() {
    if (_offset >= _bytes.length) {
      throw FormatException('Unexpected end of ASN.1 data');
    }
    final tag = _bytes[_offset++];
    final length = _readLength();
    final content = _bytes.sublist(_offset, _offset + length);
    _offset += length;

    if ((tag & 0x20) != 0) {
      final childReader = _Asn1Reader(content);
      final children = <_Asn1Node>[];
      while (childReader._offset < content.length) {
        children.add(childReader.readNode());
      }
      return _Asn1Node(tag: tag, content: content, children: children);
    }
    return _Asn1Node(tag: tag, content: content);
  }

  int _readLength() {
    final first = _bytes[_offset++];
    if (first < 0x80) return first;
    final count = first & 0x7f;
    var length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | _bytes[_offset++];
    }
    return length;
  }
}

BigInt _asn1IntegerValue(_Asn1Node node) {
  if (node.tag != 0x02) {
    throw FormatException('Expected INTEGER');
  }
  var bytes = node.content;
  if (bytes.isNotEmpty && bytes[0] == 0x00) {
    bytes = bytes.sublist(1);
  }
  if (bytes.isEmpty) return BigInt.zero;
  return BigInt.parse(
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}

Uint8List _encodePublicKeyToX509(RSAPublicKey publicKey) {
  final rsaPublicKeySeq = _asn1Sequence([
    _asn1Integer(publicKey.modulus!),
    _asn1Integer(publicKey.publicExponent!),
  ]);

  final algorithmIdentifier = _asn1Sequence([
    _asn1ObjectIdentifier(_rsaEncryptionOid),
    _asn1Null(),
  ]);

  return _asn1Sequence([
    algorithmIdentifier,
    _asn1BitString(rsaPublicKeySeq),
  ]);
}

Uint8List _encodePrivateKeyToPkcs8(RSAPrivateKey privateKey) {
  final p = privateKey.p!;
  final q = privateKey.q!;
  final d = privateKey.privateExponent!;
  final n = privateKey.modulus!;
  final e = privateKey.publicExponent!;
  final dP = d % (p - BigInt.one);
  final dQ = d % (q - BigInt.one);
  final qInv = q.modInverse(p);

  final rsaPrivateKeySeq = _asn1Sequence([
    _asn1Integer(BigInt.zero),
    _asn1Integer(n),
    _asn1Integer(e),
    _asn1Integer(d),
    _asn1Integer(p),
    _asn1Integer(q),
    _asn1Integer(dP),
    _asn1Integer(dQ),
    _asn1Integer(qInv),
  ]);

  final algorithmIdentifier = _asn1Sequence([
    _asn1ObjectIdentifier(_rsaEncryptionOid),
    _asn1Null(),
  ]);

  return _asn1Sequence([
    _asn1Integer(BigInt.zero),
    algorithmIdentifier,
    _asn1OctetString(rsaPrivateKeySeq),
  ]);
}

/// rsaEncryption OID: 1.2.840.113549.1.1.1
const List<int> _rsaEncryptionOid = [1, 2, 840, 113549, 1, 1, 1];

Uint8List _asn1Sequence(List<Uint8List> children) {
  final content = BytesBuilder(copy: false);
  for (final child in children) {
    content.add(child);
  }
  return _asn1Tag(0x30, content.toBytes());
}

Uint8List _asn1Integer(BigInt value) {
  var bytes = _bigIntToBytes(value);
  if (bytes.isNotEmpty && (bytes[0] & 0x80) != 0) {
    bytes = Uint8List.fromList([0x00, ...bytes]);
  }
  return _asn1Tag(0x02, bytes);
}

Uint8List _asn1Null() => Uint8List.fromList([0x05, 0x00]);

Uint8List _asn1OctetString(Uint8List content) => _asn1Tag(0x04, content);

Uint8List _asn1BitString(Uint8List content) {
  return _asn1Tag(0x03, Uint8List.fromList([0x00, ...content]));
}

Uint8List _asn1ObjectIdentifier(List<int> oid) {
  if (oid.length < 2) {
    throw ArgumentError('OID must have at least two components');
  }
  final body = BytesBuilder(copy: false);
  body.addByte(oid[0] * 40 + oid[1]);
  for (var i = 2; i < oid.length; i++) {
    body.add(_encodeOidComponent(oid[i]));
  }
  return _asn1Tag(0x06, body.toBytes());
}

Uint8List _encodeOidComponent(int value) {
  if (value < 0) {
    throw ArgumentError('OID component must be non-negative');
  }
  if (value < 128) {
    return Uint8List.fromList([value]);
  }
  final stack = <int>[];
  var current = value;
  stack.add(current & 0x7f);
  current >>= 7;
  while (current > 0) {
    stack.add(0x80 | (current & 0x7f));
    current >>= 7;
  }
  return Uint8List.fromList(stack.reversed.toList(growable: false));
}

Uint8List _asn1Tag(int tag, Uint8List content) {
  final length = _encodeLength(content.length);
  return Uint8List.fromList([tag, ...length, ...content]);
}

Uint8List _encodeLength(int length) {
  if (length < 128) {
    return Uint8List.fromList([length]);
  }
  final bytes = <int>[];
  var value = length;
  while (value > 0) {
    bytes.insert(0, value & 0xff);
    value >>= 8;
  }
  return Uint8List.fromList([0x80 | bytes.length, ...bytes]);
}

Uint8List _bigIntToBytes(BigInt value) {
  if (value == BigInt.zero) {
    return Uint8List.fromList([0]);
  }
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) {
    hex = '0$hex';
  }
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
