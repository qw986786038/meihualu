import 'dart:convert';
import 'dart:io';

import 'package:getx_plus/getx_plus.dart';
import 'package:http/http.dart' as http;
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/models/api/paged_api_response.dart';
import 'package:watermark_camera/utils/server_api_logger.dart';
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
    T Function(List<dynamic> list)? dataFromListJson,
    Map<String, String>? headers,
  }) {
    return post(
      path,
      body: body,
      dataFromJson: dataFromJson,
      dataFromListJson: dataFromListJson,
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
    T Function(List<dynamic> list)? dataFromListJson,
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

      final result = ApiResponse.fromJson(
        decoded,
        dataFromJson,
        fromListJson: dataFromListJson,
      );
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
    required String latitude,
    required String longitude,
    T Function(Map<String, dynamic> json)? dataFromJson,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (items.isEmpty) {
      throw FormatException('上传文件不能为空');
    }

    final requestBody = <String, dynamic>{
      'spaceId': spaceId,
      'latitude': latitude,
      'longitude': longitude,
      'files': <String>[],
      'watermarkContent': <String>[],
      'watermarkId': <int>[],
      'exifData': <String>[],
      'sha256Hash': <String>[],
    };

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(authHeaders(accessToken));
      request.fields['spaceId'] = spaceId;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;

      for (final item in items) {
        final file = File(item.filePath);
        if (!file.existsSync()) {
          throw FormatException('文件不存在: ${item.filePath}');
        }

        request.files.add(
          await http.MultipartFile.fromPath('files', item.filePath),
        );
        request.files.add(
          http.MultipartFile.fromString(
            'watermarkContent',
            item.watermarkContent,
          ),
        );
        request.files.add(
          http.MultipartFile.fromString(
            'watermarkId',
            '${item.watermarkId}',
          ),
        );
        request.files.add(
          http.MultipartFile.fromString('exifData', item.exifData),
        );
        request.files.add(
          http.MultipartFile.fromString('sha256Hash', item.sha256Hash),
        );

        (requestBody['files'] as List<String>).add(item.filePath);
        (requestBody['watermarkContent'] as List<String>)
            .add(item.watermarkContent);
        (requestBody['watermarkId'] as List<int>).add(item.watermarkId);
        (requestBody['exifData'] as List<String>).add(item.exifData);
        (requestBody['sha256Hash'] as List<String>).add(item.sha256Hash);
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
    ServerApiLogger.success(
      method: method,
      uri: uri,
      request: requestBody,
      statusCode: statusCode,
      responseBody: responseBody,
      businessCode: businessCode,
      businessMsg: businessMsg,
    );
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
    ServerApiLogger.failure(
      method: method,
      uri: uri,
      request: requestBody,
      statusCode: statusCode,
      responseBody: responseBody,
      businessCode: businessCode,
      businessMsg: businessMsg,
      reason: reason,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
