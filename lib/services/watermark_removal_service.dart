import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';
import 'package:watermark_camera/utils/watermark_eligibility.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/utils/watermark_original_store.dart';

/// 本应用水印去除服务（仅处理「梅花鹿」相册中的媒体）。
class WatermarkRemovalService {
  const WatermarkRemovalService._();

  static const String _albumName = '梅花鹿';
  static const MethodChannel _cameraxChannel = MethodChannel('camerax');

  /// 是否为本应用可去水印的媒体。
  static Future<bool> canRemoveAsset(AssetEntity asset) async {
    final ids = await WatermarkEligibility.loadWatermarkAlbumAssetIds();
    return WatermarkEligibility.isRemovable(
      asset: asset,
      watermarkAlbumAssetIds: ids,
    );
  }

  /// 去除本应用水印，优先还原备份原图；非本应用媒体返回 `null`。
  static Future<String?> removeAppWatermarkFromAsset(AssetEntity asset) async {
    final ids = await WatermarkEligibility.loadWatermarkAlbumAssetIds();
    if (!WatermarkEligibility.isRemovable(
      asset: asset,
      watermarkAlbumAssetIds: ids,
    )) {
      return null;
    }

    final file = await asset.file;
    if (file == null || !await file.exists()) return null;

    final isVideo = asset.type == AssetType.video;
    WatermarkParsedMeta? meta;
    if (!isVideo) {
      meta = await WatermarkMetadata.readFromImagePath(file.path);
    }

    final originalPath =
        await WatermarkOriginalStore.resolvePath(meta?.originalId);
    if (originalPath != null && await File(originalPath).exists()) {
      return _copyToRemovedOutput(
        originalPath,
        referencePath: file.path,
        isVideo: isVideo,
      );
    }

    return removeWatermarkFromPath(
      file.path,
      isVideo: isVideo,
      layout: meta?.layout,
    );
  }

  static Future<String?> removeWatermarkFromPath(
    String mediaPath, {
    required bool isVideo,
    WatermarkLayoutNorm? layout,
  }) async {
    if (!await File(mediaPath).exists()) return null;
    if (isVideo) {
      return _removeVideoWatermark(mediaPath);
    }
    return _removeImageWatermark(mediaPath, layout: layout);
  }

  static Future<bool> saveResult(
    String outputPath, {
    required bool isVideo,
  }) async {
    return GallerySaver.savePath(
      outputPath,
      isVideo: isVideo,
      album: _albumName,
      stampTodayDate: !isVideo,
    );
  }

  static Future<String?> _copyToRemovedOutput(
    String sourcePath, {
    required String referencePath,
    required bool isVideo,
  }) async {
    final outPath = _buildOutputPath(referencePath, isVideo: isVideo);
    try {
      await File(sourcePath).copy(outPath);
      return outPath;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _removeImageWatermark(
    String imagePath, {
    WatermarkLayoutNorm? layout,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final processed = _inpaintWatermarkRegion(decoded, layout: layout);
      final outPath = _buildOutputPath(imagePath, isVideo: false);
      await File(outPath).writeAsBytes(
        img.encodeJpg(processed, quality: 95),
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

  static img.Image _inpaintWatermarkRegion(
    img.Image source, {
    WatermarkLayoutNorm? layout,
  }) {
    final output = source.clone();
    final region = (layout ?? WatermarkLayoutNorm.kDefaultRemovalLayout)
        .toImagePixelRect(output.width, output.height);

    final left = region.left.round().clamp(0, output.width - 1);
    final top = region.top.round().clamp(0, output.height - 1);
    final right = region.right.round().clamp(left, output.width - 1);
    final bottom = region.bottom.round().clamp(top, output.height - 1);
    if (right <= left || bottom <= top) return output;

    final sampleRow = (top - 1).clamp(0, output.height - 1);
    final featherRows = math.min(3, bottom - top + 1);

    for (var y = top; y <= bottom; y++) {
      final rowOffset = y - top;
      for (var x = left; x <= right; x++) {
        final filled = _sampleInpaintPixel(output, x, sampleRow, left, right);
        if (rowOffset < featherRows) {
          final blend = (rowOffset + 1) / featherRows;
          final original = output.getPixel(x, y);
          output.setPixel(
            x,
            y,
            img.ColorRgba8(
              _blendChannel(original.r.toInt(), filled.r.toInt(), blend),
              _blendChannel(original.g.toInt(), filled.g.toInt(), blend),
              _blendChannel(original.b.toInt(), filled.b.toInt(), blend),
              _blendChannel(original.a.toInt(), filled.a.toInt(), blend),
            ),
          );
        } else {
          output.setPixel(x, y, filled);
        }
      }
    }
    return output;
  }

  static img.Color _sampleInpaintPixel(
    img.Image image,
    int x,
    int sampleRow,
    int left,
    int right,
  ) {
    final center = image.getPixel(x, sampleRow);
    if (x <= left || x >= right) return center;

    final leftPx = image.getPixel(x - 1, sampleRow);
    final rightPx = image.getPixel(x + 1, sampleRow);
    return img.ColorRgba8(
      ((center.r * 4 + leftPx.r + rightPx.r) / 6).round().clamp(0, 255),
      ((center.g * 4 + leftPx.g + rightPx.g) / 6).round().clamp(0, 255),
      ((center.b * 4 + leftPx.b + rightPx.b) / 6).round().clamp(0, 255),
      ((center.a * 4 + leftPx.a + rightPx.a) / 6).round().clamp(0, 255),
    );
  }

  static int _blendChannel(int from, int to, double t) {
    return (from * (1 - t) + to * t).round().clamp(0, 255);
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
