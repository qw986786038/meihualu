import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String aliyunPercentEncode(String value) {
  return Uri.encodeComponent(value)
      .replaceAll('+', '%20')
      .replaceAll('*', '%2A')
      .replaceAll('%7E', '~');
}

String aliyunRpcTimestamp() {
  final now = DateTime.now().toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}T'
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}Z';
}

String aliyunRpcNonce() {
  final random = Random();
  return List.generate(16, (_) => random.nextInt(10)).join();
}

String aliyunRpcSignature({
  required String accessKeySecret,
  required Map<String, String> params,
  required String method,
}) {
  final sortedKeys = params.keys.toList()..sort();
  final canonicalizedQueryString = sortedKeys
      .map(
        (key) =>
            '${aliyunPercentEncode(key)}=${aliyunPercentEncode(params[key]!)}',
      )
      .join('&');
  final stringToSign =
      '$method&${aliyunPercentEncode('/')}&${aliyunPercentEncode(canonicalizedQueryString)}';
  final key = utf8.encode('$accessKeySecret&');
  final message = utf8.encode(stringToSign);
  final digest = Hmac(sha1, key).convert(message);
  return base64Encode(digest.bytes);
}
