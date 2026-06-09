import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// 将预览区 StackBoard 截图按 BoxFit.contain 映射后合成到原图。
class MediaOverlayCompositor {
  const MediaOverlayCompositor._();

  static Size containDisplaySize(Size source, Size target) {
    if (source.width <= 0 || source.height <= 0) {
      return Size.zero;
    }
    final scale = math.min(
      target.width / source.width,
      target.height / source.height,
    );
    return Size(source.width * scale, source.height * scale);
  }

  /// 返回合成后的临时 JPEG 路径；失败时返回 `null`。
  /// 输出图片尺寸与源图解码后的像素尺寸一致，不做裁剪。
  static Future<String?> composeImage({
    required String imagePath,
    required Uint8List overlayPngBytes,
    required Size previewSize,
    int jpegQuality = 92,
  }) async {
    if (overlayPngBytes.isEmpty) return null;
    if (previewSize.width <= 0 || previewSize.height <= 0) return null;

    try {
      final raw = await File(imagePath).readAsBytes();
      final base = img.decodeImage(raw);
      if (base == null) return null;

      final overlay = img.decodeImage(overlayPngBytes);
      if (overlay == null) return null;

      final outW = base.width;
      final outH = base.height;
      if (outW <= 0 || outH <= 0) return null;

      final imagePixelSize = Size(outW.toDouble(), outH.toDouble());
      final displaySize = containDisplaySize(imagePixelSize, previewSize);
      if (displaySize.width <= 0 || displaySize.height <= 0) {
        return null;
      }

      final imageLeft = (previewSize.width - displaySize.width) / 2;
      final imageTop = (previewSize.height - displaySize.height) / 2;

      // 叠加层截图与预览逻辑尺寸对齐后，按原图显示区域映射到全分辨率
      final mapX = overlay.width / previewSize.width;
      final mapY = overlay.height / previewSize.height;

      final cropX = (imageLeft * mapX).round().clamp(0, overlay.width - 1);
      final cropY = (imageTop * mapY).round().clamp(0, overlay.height - 1);
      final cropW = math.max(
        1,
        math.min((displaySize.width * mapX).round(), overlay.width - cropX),
      );
      final cropH = math.max(
        1,
        math.min((displaySize.height * mapY).round(), overlay.height - cropY),
      );

      final overlayOnImage = img.copyCrop(
        overlay,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      // 仅按「预览中图片显示尺寸 -> 原图像素尺寸」单次缩放
      final overlayFull = img.copyResize(
        overlayOnImage,
        width: outW,
        height: outH,
        interpolation: img.Interpolation.linear,
      );

      final output = base.clone();
      img.compositeImage(
        output,
        overlayFull,
        dstX: 0,
        dstY: 0,
        blend: img.BlendMode.alpha,
      );

      if (output.width != outW || output.height != outH) {
        return null;
      }

      final outPath =
          '${Directory.systemTemp.path}/wm_editor_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(
        img.encodeJpg(output, quality: jpegQuality.clamp(1, 100)),
        flush: true,
      );
      return outPath;
    } catch (_) {
      return null;
    }
  }
}
