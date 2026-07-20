import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:native_exif/native_exif.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';

/// 通用图库保存工具，支持文件路径与二进制数据。
class GallerySaver {
  const GallerySaver._();

  static Future<bool> ensureAccess({bool toAlbum = true}) async {
    try {
      return await Gal.hasAccess(toAlbum: toAlbum) ||
          await Gal.requestAccess(toAlbum: toAlbum);
    } catch (e, st) {
      debugPrint('GallerySaver.ensureAccess failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> savePath(
    String path, {
    required bool isVideo,
    String? album,
    bool stampTodayDate = false,
    Map<String, dynamic>? watermarkData,
    Rect? watermarkRect,
    Size? watermarkBoardSize,
    String? watermarkOriginalId,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }
    if (!await ensureAccess(toAlbum: true)) {
      return false;
    }

    var saveTarget = path;
    var preparedTemp = false;
    if (!isVideo && stampTodayDate) {
      final prepared = await _prepareImageWithTodayDate(path);
      if (prepared == null) {
        return false;
      }
      saveTarget = prepared;
      preparedTemp = prepared != path;
    }

    try {
      if (!isVideo &&
          watermarkData != null &&
          watermarkRect != null &&
          watermarkBoardSize != null) {
        await WatermarkMetadata.writeToImagePath(
          saveTarget,
          data: watermarkData,
          rect: watermarkRect,
          boardSize: watermarkBoardSize,
          originalId: watermarkOriginalId,
        );
      }
      if (isVideo) {
        await Gal.putVideo(saveTarget, album: album);
      } else {
        await Gal.putImage(saveTarget, album: album);
      }
      return true;
    } on GalException {
      return false;
    } finally {
      if (preparedTemp) {
        final file = File(saveTarget);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  static Future<int> savePaths(
    List<String> paths, {
    required bool isVideo,
    String? album,
  }) async {
    var successCount = 0;
    for (final path in paths) {
      if (await savePath(path, isVideo: isVideo, album: album)) {
        successCount++;
      }
    }
    return successCount;
  }

  static Future<bool> saveImageBytes(
    Uint8List bytes, {
    String? album,
    String? fileName,
  }) async {
    return saveBytes(bytes, isVideo: false, album: album, fileName: fileName);
  }

  static Future<bool> saveVideoBytes(
    Uint8List bytes, {
    String? album,
    String? fileName,
  }) async {
    return saveBytes(bytes, isVideo: true, album: album, fileName: fileName);
  }

  static Future<bool> saveBytes(
    Uint8List bytes, {
    required bool isVideo,
    String? album,
    String? fileName,
  }) async {
    final tempFile = await _writeBytesToTemp(
      bytes,
      fileName: fileName,
      extension: isVideo ? '.mp4' : '.jpg',
    );
    try {
      return await savePath(tempFile.path, isVideo: isVideo, album: album);
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  static Future<File> _writeBytesToTemp(
    Uint8List bytes, {
    required String extension,
    String? fileName,
  }) async {
    final safeName = (fileName == null || fileName.isEmpty)
        ? '${DateTime.now().millisecondsSinceEpoch}$extension'
        : fileName;
    final normalizedName = safeName.endsWith(extension)
        ? safeName
        : '$safeName$extension';
    final file = File('${Directory.systemTemp.path}/$normalizedName');
    return file.writeAsBytes(bytes, flush: true);
  }

  /// 复制图片到临时文件，写入今天日期的 EXIF，使相册按「今天」分组。
  static Future<String?> _prepareImageWithTodayDate(String path) async {
    final source = File(path);
    if (!await source.exists()) return null;

    final now = DateTime.now();
    final ext = _imageExtension(path);
    final destPath =
        '${Directory.systemTemp.path}/WM_${_formatFileDate(now)}$ext';
    try {
      await source.copy(destPath);
      final dest = File(destPath);
      await dest.setLastModified(now);

      if (Platform.isAndroid || Platform.isIOS) {
        Exif? exif;
        try {
          exif = await Exif.fromPath(destPath);
          final exifDate = _formatExifDate(now);
          await exif.writeAttributes(<String, Object>{
            'DateTimeOriginal': exifDate,
            'DateTimeDigitized': exifDate,
          });
        } catch (_) {
          // 无 EXIF 时仍尝试保存，系统入库时间一般为当前时间。
        } finally {
          await exif?.close();
        }
      }
      return destPath;
    } catch (_) {
      return null;
    }
  }

  static String _imageExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpeg')) return '.jpeg';
    if (lower.endsWith('.jpg')) return '.jpg';
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.heic')) return '.heic';
    return '.jpg';
  }

  static String _formatExifDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}:${two(date.month)}:${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  static String _formatFileDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}_'
        '${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}
