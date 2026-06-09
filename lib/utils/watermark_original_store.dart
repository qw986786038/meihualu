import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 保存未加水印的原图，编辑/去水印时直接读取，避免底图被拉伸或模糊。
class WatermarkOriginalStore {
  const WatermarkOriginalStore._();

  static const String _channelName = 'cn.hwato.watermark_camera/app_paths';

  static Future<Directory?> _directory() async {
    if (kIsWeb) return null;
    if (!(Platform.isAndroid || Platform.isIOS)) return null;

    try {
      const channel = MethodChannel(_channelName);
      final path = await channel.invokeMethod<String>('getOriginalStoreDir');
      if (path == null || path.isEmpty) return null;
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// 复制原图到应用私有目录，返回用于元数据关联的 id。
  static Future<String?> saveFromPath(String sourcePath) async {
    final dir = await _directory();
    if (dir == null) return null;

    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = _extension(sourcePath);
    final dest = File('${dir.path}/$id$ext');
    try {
      await source.copy(dest.path);
      return id;
    } catch (_) {
      return null;
    }
  }

  /// 根据元数据 id 解析原图路径。
  static Future<String?> resolvePath(String? originalId) async {
    if (originalId == null || originalId.isEmpty) return null;
    final dir = await _directory();
    if (dir == null) return null;

    for (final ext in const ['.jpg', '.jpeg', '.png', '.heic']) {
      final file = File('${dir.path}/$originalId$ext');
      if (await file.exists()) return file.path;
    }
    return null;
  }

  static String _extension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpeg')) return '.jpeg';
    if (lower.endsWith('.jpg')) return '.jpg';
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.heic')) return '.heic';
    return '.jpg';
  }
}
