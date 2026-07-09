import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:http/http.dart' as http;
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/models/api/paged_api_response.dart';
import 'package:watermark_camera/utils/upload_path_parser.dart';

class ApiClient extends GetxService {
  Map<String, String> authHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
      'clientid': ApiConfig.clientId,
    };
  }

  Future<ApiResponse<T>> postAuth<T>(
    String path, {
    required String accessToken,
    Map<String, dynamic> body = const {},
    T Function(Map<String, dynamic> json)? dataFromJson,
    Map<String, String>? headers,
  }) {
    return post(
      path,
      body: body,
      dataFromJson: dataFromJson,
      headers: {
        ...authHeaders(accessToken),
        ...?headers,
      },
    );
  }

  Future<PagedApiResponse<T>> postAuthPaged<T>(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic> json) itemFromJson,
    Map<String, String>? headers,
  }) {
    return postPaged(
      path,
      body: body,
      itemFromJson: itemFromJson,
      headers: {
        ...authHeaders(accessToken),
        ...?headers,
      },
    );
  }

  Future<PagedApiResponse<T>> postPaged<T>(
    String path, {
    required Map<String, dynamic> body,
    required T Function(Map<String, dynamic> json) itemFromJson,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'HTTP 状态码异常',
        );
        throw FormatException('HTTP ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error, stackTrace) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'JSON 解析失败',
          error: error,
          stackTrace: stackTrace,
        );
        throw FormatException('接口响应格式错误');
      }

      if (decoded is! Map<String, dynamic>) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: '响应格式错误',
        );
        throw FormatException('接口响应格式错误');
      }

      final result = PagedApiResponse.fromJson(decoded, itemFromJson);
      if (!result.isSuccess) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
          reason: '业务失败',
        );
      } else {
        _logResponse(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
        );
      }

      return result;
    } catch (error, stackTrace) {
      if (error is! FormatException) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          reason: error.toString(),
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, dynamic> body,
    T Function(Map<String, dynamic> json)? dataFromJson,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'HTTP 状态码异常',
        );
        throw FormatException('HTTP ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error, stackTrace) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'JSON 解析失败',
          error: error,
          stackTrace: stackTrace,
        );
        throw FormatException('接口响应格式错误');
      }

      if (decoded is! Map<String, dynamic>) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: '响应格式错误',
        );
        throw FormatException('接口响应格式错误');
      }

      final result = ApiResponse.fromJson(decoded, dataFromJson);
      if (!result.isSuccess) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
          reason: '业务失败',
        );
      } else {
        _logResponse(
          method: 'POST',
          uri: uri,
          requestBody: body,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
        );
      }

      return result;
    } catch (error, stackTrace) {
      if (error is! FormatException) {
        _logFailure(
          method: 'POST',
          uri: uri,
          requestBody: body,
          reason: error.toString(),
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<T>> uploadAuthMultipart<T>(
    String path, {
    required String accessToken,
    required String filePath,
    required Map<String, String> fields,
    String fieldName = 'file',
    T Function(Map<String, dynamic> json)? dataFromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FormatException('文件不存在');
    }

    final requestBody = {
      'file': file.path,
      ...fields,
    };

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders(accessToken));
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'HTTP 状态码异常',
        );
        throw FormatException('HTTP ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error, stackTrace) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'JSON 解析失败',
          error: error,
          stackTrace: stackTrace,
        );
        throw FormatException('接口响应格式错误');
      }

      if (decoded is! Map<String, dynamic>) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: '响应格式错误',
        );
        throw FormatException('接口响应格式错误');
      }

      final result = ApiResponse<T>.fromJson(decoded, dataFromJson);
      if (!result.isSuccess) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
          reason: '业务失败',
        );
      } else {
        _logResponse(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
        );
      }
      return result;
    } catch (error, stackTrace) {
      if (error is! FormatException) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: requestBody,
          reason: error.toString(),
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<T>> uploadAuthBatchMultipart<T>(
    String path, {
    required String accessToken,
    required String spaceId,
    required List<SpaceBatchUploadItem> items,
    T Function(Map<String, dynamic> json)? dataFromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (items.isEmpty) {
      throw FormatException('上传文件不能为空');
    }

    final requestBody = <String, dynamic>{
      'spaceId': spaceId,
      'count': items.length,
    };

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders(accessToken));
      request.fields['spaceId'] = spaceId;

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final file = File(item.filePath);
        if (!file.existsSync()) {
          throw FormatException('文件不存在: ${item.filePath}');
        }

        request.fields['exifData[$i]'] = item.exifData;
        request.fields['sha256Hash[$i]'] = item.sha256Hash;
        request.fields['watermarkId[$i]'] = '${item.watermarkId}';
        request.fields['watermarkContent[$i]'] = item.watermarkContent;
        request.files.add(
          await http.MultipartFile.fromPath('files', item.filePath),
        );
        requestBody['file_$i'] = item.filePath;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'HTTP 状态码异常',
        );
        throw FormatException('HTTP ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error, stackTrace) {
        _logFailure(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'JSON 解析失败',
          error: error,
          stackTrace: stackTrace,
        );
        throw FormatException('接口响应格式错误');
      }

      if (decoded is! Map<String, dynamic>) {
        _logFailure(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: '响应格式错误',
        );
        throw FormatException('接口响应格式错误');
      }

      final result = ApiResponse<T>.fromJson(decoded, dataFromJson);
      if (!result.isSuccess) {
        _logFailure(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
          reason: '业务失败',
        );
      } else {
        _logResponse(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          statusCode: response.statusCode,
          responseBody: response.body,
          businessCode: result.code,
          businessMsg: result.msg,
        );
      }
      return result;
    } catch (error, stackTrace) {
      if (error is! FormatException) {
        _logFailure(
          method: 'BATCH_UPLOAD',
          uri: uri,
          requestBody: requestBody,
          reason: error.toString(),
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<String>> uploadAuth({
    required String path,
    required String accessToken,
    required String filePath,
    String fieldName = 'file',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FormatException('文件不存在');
    }

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders(accessToken));
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: {'file': file.path},
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'HTTP 状态码异常',
        );
        throw FormatException('HTTP ${response.statusCode}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (error, stackTrace) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: {'file': file.path},
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: 'JSON 解析失败',
          error: error,
          stackTrace: stackTrace,
        );
        throw FormatException('接口响应格式错误');
      }

      if (decoded is! Map<String, dynamic>) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: {'file': file.path},
          statusCode: response.statusCode,
          responseBody: response.body,
          reason: '响应格式错误',
        );
        throw FormatException('接口响应格式错误');
      }

      final result = ApiResponse<String>.fromJson(
        decoded,
        (json) => parseUploadPath(json) ?? '',
      );
      if (!result.isSuccess || result.data == null || result.data!.isEmpty) {
        final fallback = parseUploadPath(decoded['data']);
        final responseWithPath = ApiResponse<String>(
          code: result.code,
          msg: result.msg,
          data: fallback,
        );
        if (!responseWithPath.isSuccess ||
            responseWithPath.data == null ||
            responseWithPath.data!.isEmpty) {
          _logFailure(
            method: 'UPLOAD',
            uri: uri,
            requestBody: {'file': file.path},
            statusCode: response.statusCode,
            responseBody: response.body,
            businessCode: result.code,
            businessMsg: result.msg,
            reason: '业务失败',
          );
        } else {
          _logResponse(
            method: 'UPLOAD',
            uri: uri,
            requestBody: {'file': file.path},
            statusCode: response.statusCode,
            responseBody: response.body,
            businessCode: responseWithPath.code,
            businessMsg: responseWithPath.msg,
          );
        }
        return responseWithPath;
      }

      _logResponse(
        method: 'UPLOAD',
        uri: uri,
        requestBody: {'file': file.path},
        statusCode: response.statusCode,
        responseBody: response.body,
        businessCode: result.code,
        businessMsg: result.msg,
      );
      return result;
    } catch (error, stackTrace) {
      if (error is! FormatException) {
        _logFailure(
          method: 'UPLOAD',
          uri: uri,
          requestBody: {'file': filePath},
          reason: error.toString(),
          error: error,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required Map<String, dynamic> requestBody,
    required int statusCode,
    required String responseBody,
    int? businessCode,
    String? businessMsg,
  }) {
    final buffer = StringBuffer('API 请求成功: $method $uri');
    buffer.write(' | req=$requestBody');
    buffer.write(' | status=$statusCode');
    if (businessCode != null) buffer.write(' | code=$businessCode');
    if (businessMsg != null && businessMsg.isNotEmpty) {
      buffer.write(' | msg=$businessMsg');
    }
    if (responseBody.isNotEmpty) {
      buffer.write(' | resp=$responseBody');
    }
    debugPrint(buffer.toString());
  }

  void _logFailure({
    required String method,
    required Uri uri,
    required Map<String, dynamic> requestBody,
    int? statusCode,
    String? responseBody,
    int? businessCode,
    String? businessMsg,
    String? reason,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer('API 请求失败: $method $uri');
    buffer.write(' | req=$requestBody');
    if (statusCode != null) buffer.write(' | status=$statusCode');
    if (businessCode != null) buffer.write(' | code=$businessCode');
    if (businessMsg != null && businessMsg.isNotEmpty) {
      buffer.write(' | msg=$businessMsg');
    }
    if (reason != null && reason.isNotEmpty) {
      buffer.write(' | reason=$reason');
    }
    if (responseBody != null && responseBody.isNotEmpty) {
      buffer.write(' | resp=$responseBody');
    }
    if (error != null) buffer.write(' | error=$error');

    debugPrint(buffer.toString());
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
