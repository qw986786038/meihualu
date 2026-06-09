import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:native_exif/native_exif.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

const String kWatermarkMetaPrefix = 'WM_CAMERA:';

/// 水印在预览板上的相对位置（0~1），便于不同尺寸屏幕还原。
class WatermarkLayoutNorm {
  const WatermarkLayoutNorm({
    required this.nx,
    required this.ny,
    required this.nw,
    required this.nh,
  });

  final double nx;
  final double ny;
  final double nw;
  final double nh;

  Rect toRect(Size boardSize) {
    return Rect.fromLTWH(
      nx * boardSize.width,
      ny * boardSize.height,
      nw * boardSize.width,
      nh * boardSize.height,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nx': nx,
        'ny': ny,
        'nw': nw,
        'nh': nh,
      };

  static WatermarkLayoutNorm? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final nx = (json['nx'] as num?)?.toDouble();
    final ny = (json['ny'] as num?)?.toDouble();
    final nw = (json['nw'] as num?)?.toDouble();
    final nh = (json['nh'] as num?)?.toDouble();
    if (nx == null || ny == null || nw == null || nh == null) return null;
    return WatermarkLayoutNorm(nx: nx, ny: ny, nw: nw, nh: nh);
  }

  static WatermarkLayoutNorm fromRect(Rect rect, Size boardSize) {
    if (boardSize.width <= 0 || boardSize.height <= 0) {
      return const WatermarkLayoutNorm(nx: 0.02, ny: 0.78, nw: 0.72, nh: 0.18);
    }
    return WatermarkLayoutNorm(
      nx: rect.left / boardSize.width,
      ny: rect.top / boardSize.height,
      nw: rect.width / boardSize.width,
      nh: rect.height / boardSize.height,
    );
  }

  /// 将归一化布局映射到图片像素区域（用于精确去水印）。
  Rect toImagePixelRect(
    int imageWidth,
    int imageHeight, {
    int padX = 4,
    int padY = 4,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) return Rect.zero;

    final left = (nx * imageWidth).floor() - padX;
    final top = (ny * imageHeight).floor() - padY;
    final right = ((nx + nw) * imageWidth).ceil() + padX;
    final bottom = ((ny + nh) * imageHeight).ceil() + padY;

    return Rect.fromLTRB(
      left.toDouble().clamp(0, imageWidth - 1),
      top.toDouble().clamp(0, imageHeight - 1),
      right.toDouble().clamp(0, imageWidth.toDouble()),
      bottom.toDouble().clamp(0, imageHeight.toDouble()),
    );
  }

  static const WatermarkLayoutNorm kDefaultRemovalLayout = WatermarkLayoutNorm(
    nx: 0.02,
    ny: 0.78,
    nw: 0.72,
    nh: 0.18,
  );
}

class WatermarkParsedMeta {
  const WatermarkParsedMeta({
    required this.data,
    this.layout,
    this.originalId,
  });

  final Map<String, dynamic> data;
  final WatermarkLayoutNorm? layout;

  /// 关联到 [WatermarkOriginalStore] 中保存的无水印原图。
  final String? originalId;
}

class WatermarkMetadata {
  const WatermarkMetadata._();

  static String encodeUserComment({
    required Map<String, dynamic> data,
    required Rect rect,
    required Size boardSize,
    String? originalId,
  }) {
    final layout = WatermarkLayoutNorm.fromRect(rect, boardSize);
    final payload = <String, dynamic>{
      'v': 1,
      'data': data,
      'layout': layout.toJson(),
      if (originalId != null && originalId.isNotEmpty) 'originalId': originalId,
    };
    return '$kWatermarkMetaPrefix${jsonEncode(payload)}';
  }

  static WatermarkParsedMeta? decodeUserComment(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (!trimmed.startsWith(kWatermarkMetaPrefix)) return null;
    try {
      final jsonStr = trimmed.substring(kWatermarkMetaPrefix.length);
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      final rawData = decoded['data'];
      if (rawData is! Map) return null;
      final data = Map<String, dynamic>.from(rawData);
      final layout = WatermarkLayoutNorm.fromJson(
        decoded['layout'] is Map
            ? Map<String, dynamic>.from(decoded['layout'] as Map)
            : null,
      );
      final originalId = decoded['originalId']?.toString();
      return WatermarkParsedMeta(
        data: data,
        layout: layout,
        originalId: originalId,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<WatermarkParsedMeta?> readFromImagePath(String path) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;
    final lower = path.toLowerCase();
    if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) return null;

    Exif? exif;
    try {
      exif = await Exif.fromPath(path);
      final comment = await exif.getAttribute<String>('UserComment');
      final parsed = decodeUserComment(comment);
      if (parsed != null) return parsed;
      return await _fallbackFromExif(exif);
    } catch (_) {
      return null;
    } finally {
      await exif?.close();
    }
  }

  static Future<void> writeToImagePath(
    String path, {
    required Map<String, dynamic> data,
    required Rect rect,
    required Size boardSize,
    String? originalId,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final lower = path.toLowerCase();
    if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) return;

    Exif? exif;
    try {
      exif = await Exif.fromPath(path);
      await exif.writeAttribute(
        'UserComment',
        encodeUserComment(
          data: data,
          rect: rect,
          boardSize: boardSize,
          originalId: originalId,
        ),
      );
    } catch (_) {
      // 元数据写入失败不影响保存图片。
    } finally {
      await exif?.close();
    }
  }

  static Future<WatermarkParsedMeta> _fallbackFromExif(Exif exif) async {
    final data = createDefaultWatermarkData();
    try {
      final original = await exif.getOriginalDate();
      if (original != null) {
        data['time'] =
            '${original.hour.toString().padLeft(2, '0')}:${original.minute.toString().padLeft(2, '0')}';
        data['date'] =
            '${original.year}-${original.month.toString().padLeft(2, '0')}-${original.day.toString().padLeft(2, '0')}';
        data[kWatermarkDataShowWeekday] = true;
        data['weekday'] = const [
          '星期一',
          '星期二',
          '星期三',
          '星期四',
          '星期五',
          '星期六',
          '星期日',
        ][original.weekday - 1];
      }
      final lat = await exif.getAttribute<String>('GPSLatitude');
      final lon = await exif.getAttribute<String>('GPSLongitude');
      if (lat != null &&
          lon != null &&
          lat.isNotEmpty &&
          lon.isNotEmpty) {
        data[kWatermarkDataShowCoordinate] = true;
      }
    } catch (_) {}

    return WatermarkParsedMeta(
      data: data,
      layout: const WatermarkLayoutNorm(
        nx: 0.02,
        ny: 0.78,
        nw: 0.72,
        nh: 0.18,
      ),
    );
  }

  static WatermarkParsedMeta defaultMeta() {
    return WatermarkParsedMeta(
      data: createDefaultWatermarkData(),
      layout: const WatermarkLayoutNorm(
        nx: 0.02,
        ny: 0.78,
        nw: 0.72,
        nh: 0.18,
      ),
    );
  }
}
