import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:getx_plus/getx_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:watermark_camera/config/aliyun_secrets.dart';
import 'package:watermark_camera/utils/aliyun_oss_upload.dart';
import 'package:watermark_camera/utils/aliyun_rpc_sign.dart';

class ImageTagResult {
  const ImageTagResult({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;
}

class AliyunImageTaggingException implements Exception {
  AliyunImageTaggingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AliyunImageTaggingService extends GetxService {
  static const String _accessKeyId = String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_ID',
    defaultValue: AliyunSecrets.accessKeyId,
  );
  static const String _accessKeySecret = String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_SECRET',
    defaultValue: AliyunSecrets.accessKeySecret,
  );
  static const String _missingKeyText = '请配置阿里云 AccessKey';
  static const int _maxImageBytes = 3 * 1024 * 1024;

  bool get isConfigured =>
      _accessKeyId.isNotEmpty && _accessKeySecret.isNotEmpty;

  Future<List<ImageTagResult>> tagImageBytes(Uint8List bytes) async {
    if (!isConfigured) {
      throw AliyunImageTaggingException(_missingKeyText);
    }

    final prepared = await _prepareImageBytes(bytes);
    final ossCredentials = await _getOssStsToken();
    final upload = await uploadToViapiTempOss(
      credentials: ossCredentials,
      ownerAccessKeyId: _accessKeyId,
      bytes: prepared,
      fileName: 'tagging_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return _tagImageByUrl(upload.url);
  }

  Future<Uint8List> _prepareImageBytes(Uint8List bytes) async {
    if (bytes.length <= _maxImageBytes) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw AliyunImageTaggingException('无法读取图片');
    }

    for (final quality in <int>[90, 80, 70, 60, 50, 40]) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );
      if (encoded.length <= _maxImageBytes) return encoded;
    }

    var resized = decoded;
    for (var scale = 0.9; scale >= 0.3; scale -= 0.1) {
      final width = max(1, (decoded.width * scale).round());
      final height = max(1, (decoded.height * scale).round());
      resized = img.copyResize(decoded, width: width, height: height);
      final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
      if (encoded.length <= _maxImageBytes) return encoded;
    }

    throw AliyunImageTaggingException('图片过大，请换一张较小的图片');
  }

  Future<AliyunOssCredentials> _getOssStsToken() async {
    final body = await _callRpcApi(
      endpoint: 'viapiutils.cn-shanghai.aliyuncs.com',
      action: 'GetOssStsToken',
      version: '2020-04-01',
    );
    final data = body['Data'];
    if (data is! Map) {
      throw AliyunImageTaggingException('获取 OSS 临时凭证失败');
    }

    final accessKeyId = data['AccessKeyId']?.toString() ?? '';
    final accessKeySecret = data['AccessKeySecret']?.toString() ?? '';
    final securityToken = data['SecurityToken']?.toString() ?? '';
    if (accessKeyId.isEmpty ||
        accessKeySecret.isEmpty ||
        securityToken.isEmpty) {
      throw AliyunImageTaggingException('OSS 临时凭证不完整');
    }

    return AliyunOssCredentials(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
      securityToken: securityToken,
    );
  }

  Future<List<ImageTagResult>> _tagImageByUrl(String imageUrl) async {
    final body = await _callRpcApi(
      endpoint: 'imagerecog.cn-shanghai.aliyuncs.com',
      action: 'TaggingImage',
      version: '2019-09-30',
      businessParams: <String, String>{'ImageURL': imageUrl},
    );

    final data = body['Data'];
    if (data is! Map) {
      throw AliyunImageTaggingException('识别结果为空');
    }

    final tags = data['Tags'];
    if (tags is! List || tags.isEmpty) {
      throw AliyunImageTaggingException('未识别到物品');
    }

    final results = <ImageTagResult>[];
    for (final raw in tags) {
      if (raw is! Map) continue;
      final label = raw['Value']?.toString().trim() ?? '';
      if (label.isEmpty) continue;
      final confidence = _readConfidence(raw['Confidence']);
      if (confidence <= 0) continue;
      results.add(ImageTagResult(label: label, confidence: confidence));
    }

    if (results.isEmpty) {
      throw AliyunImageTaggingException('未识别到有效标签');
    }
    return results;
  }

  Future<Map<String, dynamic>> _callRpcApi({
    required String endpoint,
    required String action,
    required String version,
    Map<String, String>? businessParams,
  }) async {
    final params = <String, String>{
      'Format': 'JSON',
      'Version': version,
      'AccessKeyId': _accessKeyId,
      'SignatureMethod': 'HMAC-SHA1',
      'Timestamp': aliyunRpcTimestamp(),
      'SignatureVersion': '1.0',
      'SignatureNonce': aliyunRpcNonce(),
      'Action': action,
      'RegionId': 'cn-shanghai',
      ...?businessParams,
    };
    params['Signature'] = aliyunRpcSignature(
      accessKeySecret: _accessKeySecret,
      params: params,
      method: 'POST',
    );

    final uri = Uri.https(endpoint, '/');
    final response = await http.post(uri, body: params);
    if (response.statusCode != 200) {
      throw AliyunImageTaggingException('请求失败 (${response.statusCode})');
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw AliyunImageTaggingException('响应格式错误');
    }

    final code = body['Code']?.toString();
    if (code != null && code.isNotEmpty && code != '200') {
      final message = body['Message']?.toString() ?? '识别失败';
      throw AliyunImageTaggingException(message);
    }

    return Map<String, dynamic>.from(body);
  }

  double _readConfidence(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
