import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';

/// 通用图库保存工具，支持文件路径与二进制数据。
class GallerySaver {
  const GallerySaver._();

  static Future<bool> ensureAccess({bool toAlbum = true}) async {
    return await Gal.hasAccess(toAlbum: toAlbum) ||
        await Gal.requestAccess(toAlbum: toAlbum);
  }

  static Future<bool> savePath(
    String path, {
    required bool isVideo,
    String? album,
  }) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }
    if (!await ensureAccess(toAlbum: true)) {
      return false;
    }
    try {
      if (isVideo) {
        await Gal.putVideo(path, album: album);
      } else {
        await Gal.putImage(path, album: album);
      }
      return true;
    } on GalException {
      return false;
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
}
