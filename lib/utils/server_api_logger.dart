import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 后端服务器接口请求/响应日志（仅用于 [ApiConfig.baseUrl] 相关请求）。
abstract final class ServerApiLogger {
  static void success({
    required String method,
    required Uri uri,
    Map<String, dynamic>? request,
    required int statusCode,
    required String responseBody,
    int? businessCode,
    String? businessMsg,
  }) {
    _printBlock(
      title: '[服务器API成功] $method $uri',
      lines: [
        if (request != null && request.isNotEmpty) '请求: ${_encode(request)}',
        _statusLine(statusCode, businessCode, businessMsg),
        '响应:',
        _prettyBody(responseBody),
      ],
    );
  }

  static void failure({
    required String method,
    required Uri uri,
    Map<String, dynamic>? request,
    int? statusCode,
    String? responseBody,
    int? businessCode,
    String? businessMsg,
    String? reason,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _printBlock(
      title: '[服务器API失败] $method $uri',
      lines: [
        if (request != null && request.isNotEmpty) '请求: ${_encode(request)}',
        if (statusCode != null)
          _statusLine(statusCode, businessCode, businessMsg),
        if (reason != null && reason.isNotEmpty) '原因: $reason',
        if (error != null) '异常: $error',
        if (responseBody != null && responseBody.isNotEmpty) ...[
          '响应:',
          _prettyBody(responseBody),
        ],
        if (stackTrace != null) '堆栈:\n$stackTrace',
      ],
    );
  }

  static void exception({
    required String method,
    required Uri uri,
    Map<String, dynamic>? request,
    required Object error,
    StackTrace? stackTrace,
  }) {
    failure(
      method: method,
      uri: uri,
      request: request,
      reason: '网络或解析异常',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _statusLine(
    int statusCode,
    int? businessCode,
    String? businessMsg,
  ) {
    final buffer = StringBuffer('状态: $statusCode');
    if (businessCode != null) buffer.write(' | code=$businessCode');
    if (businessMsg != null && businessMsg.isNotEmpty) {
      buffer.write(' | msg=$businessMsg');
    }
    return buffer.toString();
  }

  static String _prettyBody(String body) {
    if (body.isEmpty) return '(empty)';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }

  static String _encode(Object value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  static void _printBlock({
    required String title,
    required List<String> lines,
  }) {
    if (!kDebugMode) return;

    _emit(title);
    for (final line in lines) {
      _emit(line);
    }
  }

  static void _emit(String message) {
    const chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint(message);
      return;
    }
    for (var i = 0; i < message.length; i += chunkSize) {
      debugPrint(message.substring(i, math.min(i + chunkSize, message.length)));
    }
  }
}
