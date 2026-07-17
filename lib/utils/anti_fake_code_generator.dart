import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 与后端 Java [AntiFakeCodeGenerator] 对齐的防伪码生成。
///
/// ```java
/// public static String generate(String imageHash) {
///   String hash = sha256(imageHash);
///   BigInteger bigInt = new BigInteger(hash, 16);
///   String base36 = bigInt.toString(36).toUpperCase();
///   return base36.length() >= 14 ? base36.substring(0, 14)
///       : String.format("%14s", base36).replace(' ', '0');
/// }
/// ```
abstract final class AntiFakeCodeGenerator {
  /// [imageHash] 为文件内容的 SHA256 十六进制字符串。
  static String generate(String imageHash) {
    final hash = sha256.convert(utf8.encode(imageHash)).toString();
    final bigInt = BigInt.parse(hash, radix: 16);
    var base36 = bigInt.toRadixString(36).toUpperCase();
    if (base36.length >= 14) {
      return base36.substring(0, 14);
    }
    return base36.padLeft(14, '0');
  }
}

/// 拍摄时写入 EXIF / 验真接口提交的凭证信息。
class AntiFakeProof {
  const AntiFakeProof({
    required this.imageHash,
    required this.antiFakeCode,
    required this.signature,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationSource,
    required this.deviceId,
    required this.claimedWidth,
    required this.claimedHeight,
    this.extraEntropy,
  });

  final String imageHash;
  final String antiFakeCode;
  final String signature;
  final int timestamp;
  final double latitude;
  final double longitude;
  final String locationSource;
  final String deviceId;
  final int claimedWidth;
  final int claimedHeight;
  final String? extraEntropy;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'imageHash': imageHash,
        'antiFakeCode': antiFakeCode,
        'signature': signature,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'locationSource': locationSource,
        'deviceId': deviceId,
        'claimedWidth': claimedWidth,
        'claimedHeight': claimedHeight,
        'extraEntropy': extraEntropy,
      };

  String toJsonString() => jsonEncode(toJson());

  static AntiFakeProof? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final imageHash = json['imageHash']?.toString();
    final antiFakeCode = json['antiFakeCode']?.toString();
    final signature = json['signature']?.toString();
    final deviceId = json['deviceId']?.toString();
    final locationSource = json['locationSource']?.toString();
    final timestamp = _asInt(json['timestamp']);
    final latitude = _asDouble(json['latitude']);
    final longitude = _asDouble(json['longitude']);
    final claimedWidth = _asInt(json['claimedWidth']);
    final claimedHeight = _asInt(json['claimedHeight']);
    if (imageHash == null ||
        imageHash.isEmpty ||
        antiFakeCode == null ||
        antiFakeCode.isEmpty ||
        signature == null ||
        signature.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty ||
        locationSource == null ||
        locationSource.isEmpty ||
        timestamp == null ||
        latitude == null ||
        longitude == null ||
        claimedWidth == null ||
        claimedHeight == null) {
      return null;
    }
    final extra = json['extraEntropy']?.toString();
    return AntiFakeProof(
      imageHash: imageHash,
      antiFakeCode: antiFakeCode,
      signature: signature,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      locationSource: locationSource,
      deviceId: deviceId,
      claimedWidth: claimedWidth,
      claimedHeight: claimedHeight,
      extraEntropy: (extra == null || extra.isEmpty) ? null : extra,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
