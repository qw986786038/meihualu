import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:native_exif/native_exif.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class SpaceUploadPayload {
  const SpaceUploadPayload({
    required this.sha256Hash,
    required this.exifData,
    required this.watermarkId,
    required this.watermarkContent,
  });

  final String sha256Hash;
  final String exifData;
  final int watermarkId;
  final String watermarkContent;
}

abstract final class SpaceUploadHelper {
  static const _exifKeys = [
    'GPSLatitude',
    'GPSLongitude',
    'GPSAltitude',
    'DateTimeOriginal',
    'DateTime',
    'UserComment',
    'Make',
    'Model',
    'Orientation',
  ];

  static Future<SpaceUploadPayload> build({
    required String filePath,
    required Map<String, dynamic> watermarkData,
    required AMapLocationService locationService,
    DateTime? captureTime,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final sha256Hash = sha256.convert(bytes).toString();
    final exifData = await _readExifJson(filePath);
    final templateId = watermarkString(
      watermarkData,
      kWatermarkDataTemplateId,
      fallback: kDefaultWatermarkTemplateId,
    );
    final watermarkId = watermarkBackendId(templateId);
    final watermarkContent = jsonEncode(
      _buildWatermarkContent(
        watermarkData: watermarkData,
        locationService: locationService,
        captureTime: captureTime ?? DateTime.now(),
      ),
    );

    return SpaceUploadPayload(
      sha256Hash: sha256Hash,
      exifData: exifData,
      watermarkId: watermarkId,
      watermarkContent: watermarkContent,
    );
  }

  /// 手动上传相册素材：仅本 App 拍摄的图片会携带水印内容。
  static Future<SpaceUploadPayload> buildForManualUpload({
    required String filePath,
    DateTime? captureTime,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final sha256Hash = sha256.convert(bytes).toString();
    final exifData = await _readExifJson(filePath);
    final parsed = await WatermarkMetadata.readFromImagePath(filePath);
    final fallbackTime = captureTime ?? DateTime.now();

    if (parsed != null && _isAppCaptured(parsed)) {
      final templateId = watermarkString(
        parsed.data,
        kWatermarkDataTemplateId,
        fallback: kDefaultWatermarkTemplateId,
      );
      return SpaceUploadPayload(
        sha256Hash: sha256Hash,
        exifData: exifData,
        watermarkId: watermarkBackendId(templateId),
        watermarkContent: jsonEncode(
          _buildWatermarkContentFromParsed(
            data: parsed.data,
            exifData: exifData,
            fallbackTime: fallbackTime,
          ),
        ),
      );
    }

    return SpaceUploadPayload(
      sha256Hash: sha256Hash,
      exifData: exifData,
      watermarkId: watermarkBackendId(kDefaultWatermarkTemplateId),
      watermarkContent: '{}',
    );
  }

  static bool _isAppCaptured(WatermarkParsedMeta parsed) {
    if (parsed.originalId != null && parsed.originalId!.isNotEmpty) {
      return true;
    }
    return parsed.data.containsKey(kWatermarkDataTemplateId);
  }

  static Map<String, String> _buildWatermarkContentFromParsed({
    required Map<String, dynamic> data,
    required String exifData,
    required DateTime fallbackTime,
  }) {
    final gps = _gpsFromExifJson(exifData);
    final location = watermarkString(data, kWatermarkDataSelectedAddress);
    return {
      'time': _resolveCaptureTime(data, fallbackTime),
      'latitude': gps.$1,
      'longitude': gps.$2,
      'location': location,
    };
  }

  static String _resolveCaptureTime(
    Map<String, dynamic> data,
    DateTime fallbackTime,
  ) {
    final date = watermarkString(data, 'date');
    final time = watermarkString(data, 'time');
    if (date.isNotEmpty && time.isNotEmpty) {
      return '$date $time';
    }
    return _formatCaptureTime(fallbackTime);
  }

  static (String, String) _gpsFromExifJson(String exifData) {
    try {
      final decoded = jsonDecode(exifData);
      if (decoded is! Map<String, dynamic>) return ('', '');
      final lat = decoded['GPSLatitude']?.toString().trim() ?? '';
      final lon = decoded['GPSLongitude']?.toString().trim() ?? '';
      return (lat, lon);
    } catch (_) {
      return ('', '');
    }
  }

  static Map<String, String> _buildWatermarkContent({
    required Map<String, dynamic> watermarkData,
    required AMapLocationService locationService,
    required DateTime captureTime,
  }) {
    final location = _resolveAddress(watermarkData, locationService);
    final lat = locationService.latestLocation.value?.latitude;
    final lon = locationService.latestLocation.value?.longitude;

    return {
      'time': _formatCaptureTime(captureTime),
      'latitude': lat != null ? lat.toStringAsFixed(6) : '',
      'longitude': lon != null ? lon.toStringAsFixed(6) : '',
      'location': location,
    };
  }

  static String _resolveAddress(
    Map<String, dynamic> watermarkData,
    AMapLocationService locationService,
  ) {
    final selected = watermarkString(
      watermarkData,
      kWatermarkDataSelectedAddress,
    );
    if (selected.isNotEmpty && !_isPlaceholderAddress(selected)) {
      return selected;
    }

    final live = locationService.watermarkAddress.value.trim();
    if (live.isNotEmpty && !_isPlaceholderAddress(live)) {
      return live;
    }
    return '';
  }

  static bool _isPlaceholderAddress(String value) {
    const placeholders = {
      '定位中...',
      '定位失败',
      '定位权限未开启',
      '定位权限被永久拒绝',
      '请开启定位服务',
      '请配置高德 Key',
      '当前平台不支持高德定位',
      '高德初始化失败',
      '高德定位初始化失败，',
    };
    return placeholders.contains(value);
  }

  static String _formatCaptureTime(DateTime time) {
    final year = time.year;
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  static Future<String> _readExifJson(String filePath) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return '{}';

    final lower = filePath.toLowerCase();
    if (!lower.endsWith('.jpg') &&
        !lower.endsWith('.jpeg') &&
        !lower.endsWith('.heic')) {
      return '{}';
    }

    Exif? exif;
    try {
      exif = await Exif.fromPath(filePath);
      final attrs = <String, dynamic>{};
      for (final key in _exifKeys) {
        try {
          final value = await exif.getAttribute(key);
          if (value != null) {
            attrs[key] = value.toString();
          }
        } catch (_) {}
      }
      return jsonEncode(attrs);
    } catch (_) {
      return '{}';
    } finally {
      await exif?.close();
    }
  }
}
