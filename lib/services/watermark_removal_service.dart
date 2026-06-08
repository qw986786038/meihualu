import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';

/// AI 去水印处理服务。
class WatermarkRemovalService {
  const WatermarkRemovalService._();

  static const String _albumName = '水印相机';
  static const MethodChannel _cameraxChannel = MethodChannel('camerax');

  /// 对图片或视频执行去水印处理，返回输出文件路径。
  static Future<String?> removeWatermarkFromAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !await file.exists()) return null;
    return removeWatermarkFromPath(
      file.path,
      isVideo: asset.type == AssetType.video,
    );
  }

  static Future<String?> removeWatermarkFromPath(
    String mediaPath, {
    required bool isVideo,
  }) async {
    if (!await File(mediaPath).exists()) return null;
    if (isVideo) {
      return _removeVideoWatermark(mediaPath);
    }
    return _removeImageWatermark(mediaPath);
  }

  static Future<bool> saveResult(
    String outputPath, {
    required bool isVideo,
  }) async {
    return GallerySaver.savePath(
      outputPath,
      isVideo: isVideo,
      album: _albumName,
    );
  }

  static Future<String?> _removeImageWatermark(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final processed = _heuristicRemoveBottomWatermark(decoded);
      final outPath = _buildOutputPath(imagePath, isVideo: false);
      await File(outPath).writeAsBytes(
        img.encodeJpg(processed, quality: 92),
        flush: true,
      );
      return outPath;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _removeVideoWatermark(String videoPath) async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return null;
    }

    final outPath = _buildOutputPath(videoPath, isVideo: true);
    try {
      final ok = await _cameraxChannel.invokeMethod<bool>(
        'removeVideoWatermark',
        <String, dynamic>{
          'inputPath': videoPath,
          'outputPath': outPath,
        },
      );
      if (ok != true || !await File(outPath).exists()) return null;
      return outPath;
    } catch (e, st) {
      debugPrint('removeVideoWatermark failed: $e\n$st');
      return null;
    }
  }

  static img.Image _heuristicRemoveBottomWatermark(img.Image source) {
    final output = source.clone();
    final cropHeight = (output.height * 0.22).round().clamp(1, output.height);
    final cropWidth = (output.width * 0.72).round().clamp(1, output.width);
    final sampleY = (output.height - cropHeight - (output.height * 0.04).round())
        .clamp(0, output.height - 1);

    for (var y = sampleY; y < output.height; y++) {
      for (var x = 0; x < cropWidth; x++) {
        final pixel = output.getPixel(x.clamp(0, output.width - 1), sampleY);
        output.setPixel(x, y, pixel);
      }
    }
    return output;
  }

  static String _buildOutputPath(String sourcePath, {required bool isVideo}) {
    final dot = sourcePath.lastIndexOf('.');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = isVideo ? '.mp4' : '.jpg';
    if (dot <= 0) return '${sourcePath}_removed_$timestamp$ext';
    final base = sourcePath.substring(0, dot);
    return '${base}_removed_$timestamp$ext';
  }
}
