import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:getx_plus/getx_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:watermark_camera/config/aliyun_secrets.dart';
import 'package:watermark_camera/utils/aliyun_oss_upload.dart';
import 'package:watermark_camera/utils/aliyun_rpc_sign.dart';

class OcrWordResult {
  const OcrWordResult({
    required this.word,
    required this.confidence,
  });

  final String word;
  final double confidence;
}

class ScreenTextOcrResult {
  const ScreenTextOcrResult({
    required this.content,
    required this.words,
  });

  final String content;
  final List<OcrWordResult> words;
}

class AliyunOcrException implements Exception {
  AliyunOcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 阿里云通用 OCR，用于识别 LED 屏幕等场景中的广告文字。
class AliyunOcrService extends GetxService {
  static const String _accessKeyId = String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_ID',
    defaultValue: AliyunSecrets.accessKeyId,
  );
  static const String _accessKeySecret = String.fromEnvironment(
    'ALIYUN_ACCESS_KEY_SECRET',
    defaultValue: AliyunSecrets.accessKeySecret,
  );
  static const String _missingKeyText = '请配置阿里云 AccessKey';
  static const int _maxImageBytes = 4 * 1024 * 1024;

  bool get isConfigured =>
      _accessKeyId.isNotEmpty && _accessKeySecret.isNotEmpty;

  Future<ScreenTextOcrResult> recognizeImageBytes(Uint8List bytes) async {
    if (!isConfigured) {
      throw AliyunOcrException(_missingKeyText);
    }

    final prepared = await _prepareImageBytes(bytes);
    final ossCredentials = await _getOssStsToken();
    final upload = await uploadToViapiTempOss(
      credentials: ossCredentials,
      ownerAccessKeyId: _accessKeyId,
      bytes: prepared,
      fileName: 'ocr_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return _recognizeByUrl(upload.url);
  }

  Future<Uint8List> _prepareImageBytes(Uint8List bytes) async {
    if (bytes.length <= _maxImageBytes) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw AliyunOcrException('无法读取图片');
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

    throw AliyunOcrException('图片过大，请换一张较小的图片');
  }

  Future<AliyunOssCredentials> _getOssStsToken() async {
    final body = await _callRpcApi(
      endpoint: 'viapiutils.cn-shanghai.aliyuncs.com',
      action: 'GetOssStsToken',
      version: '2020-04-01',
      regionId: 'cn-shanghai',
    );
    final data = body['Data'];
    if (data is! Map) {
      throw AliyunOcrException('获取 OSS 临时凭证失败');
    }

    final accessKeyId = data['AccessKeyId']?.toString() ?? '';
    final accessKeySecret = data['AccessKeySecret']?.toString() ?? '';
    final securityToken = data['SecurityToken']?.toString() ?? '';
    if (accessKeyId.isEmpty ||
        accessKeySecret.isEmpty ||
        securityToken.isEmpty) {
      throw AliyunOcrException('OSS 临时凭证不完整');
    }

    return AliyunOssCredentials(
      accessKeyId: accessKeyId,
      accessKeySecret: accessKeySecret,
      securityToken: securityToken,
    );
  }

  Future<ScreenTextOcrResult> _recognizeByUrl(String imageUrl) async {
    final body = await _callRpcApi(
      endpoint: 'ocr-api.cn-hangzhou.aliyuncs.com',
      action: 'RecognizeGeneral',
      version: '2021-07-07',
      regionId: 'cn-hangzhou',
      businessParams: <String, String>{'Url': imageUrl},
    );

    final data = _parseOcrData(body['Data']);
    if (data == null) {
      throw AliyunOcrException('识别结果为空');
    }

    final content = _readOcrField(data, 'Content', 'content')?.trim() ?? '';
    final words = <OcrWordResult>[];
    final prismWords = data['PrismWordsInfo'] ?? data['prism_wordsInfo'];
    if (prismWords is List) {
      for (final raw in prismWords) {
        if (raw is! Map) continue;
        final word =
            _readOcrField(raw, 'Word', 'word')?.trim() ?? '';
        if (word.isEmpty) continue;
        words.add(
          OcrWordResult(
            word: word,
            confidence: _readConfidence(
              raw['Prob'] ?? raw['prob'] ?? raw['Confidence'] ?? raw['confidence'],
            ),
          ),
        );
      }
    }

    if (content.isEmpty && words.isEmpty) {
      throw AliyunOcrException('未识别到屏幕文字，请对准 LED 广告屏重试');
    }

    return ScreenTextOcrResult(
      content: content.isNotEmpty ? content : words.map((e) => e.word).join('\n'),
      words: words,
    );
  }

  Future<Map<String, dynamic>> _callRpcApi({
    required String endpoint,
    required String action,
    required String version,
    required String regionId,
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
      'RegionId': regionId,
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
      throw AliyunOcrException(_readRpcErrorMessage(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw AliyunOcrException('响应格式错误');
    }

    final code = body['Code']?.toString();
    if (code != null && code.isNotEmpty && code != '200') {
      final message = body['Message']?.toString() ?? '识别失败';
      throw AliyunOcrException(message);
    }

    return Map<String, dynamic>.from(body);
  }

  /// 阿里云 OCR 的 Data 字段是 JSON 字符串，需二次解析。
  Map<String, dynamic>? _parseOcrData(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  String? _readOcrField(Map map, String pascalKey, String camelKey) {
    final value = map[pascalKey] ?? map[camelKey];
    if (value == null) return null;
    return value.toString();
  }

  double _readConfidence(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readRpcErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        final message = body['Message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return '请求失败 (${response.statusCode})';
  }
}
