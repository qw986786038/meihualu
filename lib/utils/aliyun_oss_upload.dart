import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AliyunOssCredentials {
  const AliyunOssCredentials({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.securityToken,
  });

  final String accessKeyId;
  final String accessKeySecret;
  final String securityToken;
}

class AliyunOssUploadResult {
  const AliyunOssUploadResult({
    required this.objectName,
    required this.url,
  });

  final String objectName;
  final String url;
}

Future<AliyunOssUploadResult> uploadToViapiTempOss({
  required AliyunOssCredentials credentials,
  required String ownerAccessKeyId,
  required Uint8List bytes,
  required String fileName,
  String contentType = 'image/jpeg',
  String bucket = 'viapi-customer-temp',
  String region = 'oss-cn-shanghai',
}) async {
  final nonce = _randomNonce(6);
  final objectName = '$ownerAccessKeyId/$nonce/$fileName';
  final host = '$bucket.$region.aliyuncs.com';
  final date = _httpDate();
  final authorization = _buildAuthorization(
    accessKeySecret: credentials.accessKeySecret,
    method: 'PUT',
    contentType: contentType,
    date: date,
    securityToken: credentials.securityToken,
    bucket: bucket,
    objectName: objectName,
  );

  final uri = Uri.https(host, '/$objectName');
  final response = await http.put(
    uri,
    headers: <String, String>{
      'Date': date,
      'Content-Type': contentType,
      'x-oss-security-token': credentials.securityToken,
      'Authorization': 'OSS ${credentials.accessKeyId}:$authorization',
    },
    body: bytes,
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw AliyunOssUploadException(
      'OSS 上传失败 (${response.statusCode})',
      body: response.body,
    );
  }

  return AliyunOssUploadResult(
    objectName: objectName,
    url: 'https://$host/$objectName',
  );
}

String _buildAuthorization({
  required String accessKeySecret,
  required String method,
  required String contentType,
  required String date,
  required String securityToken,
  required String bucket,
  required String objectName,
}) {
  final canonicalizedOssHeaders =
      'x-oss-security-token:$securityToken\n';
  final canonicalizedResource = '/$bucket/$objectName';
  final stringToSign = '$method\n\n$contentType\n$date\n'
      '$canonicalizedOssHeaders$canonicalizedResource';
  final key = utf8.encode(accessKeySecret);
  final message = utf8.encode(stringToSign);
  final digest = Hmac(sha1, key).convert(message);
  return base64Encode(digest.bytes);
}

String _httpDate() {
  const weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final now = DateTime.now().toUtc();
  final weekday = weekdays[now.weekday - 1];
  final month = months[now.month - 1];
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final second = now.second.toString().padLeft(2, '0');
  return '$weekday, $day $month ${now.year} $hour:$minute:$second GMT';
}

String _randomNonce(int length) {
  const chars =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(chars[(DateTime.now().microsecondsSinceEpoch + i) % chars.length]);
  }
  return buffer.toString();
}

class AliyunOssUploadException implements Exception {
  AliyunOssUploadException(this.message, {this.body});

  final String message;
  final String? body;

  @override
  String toString() => body == null ? message : '$message: $body';
}
