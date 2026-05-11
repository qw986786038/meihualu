import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// 原生侧（Android Bitmap / UIKit）合成水印，远比纯 Dart [image] 包编解码快。
const _mergeOverlayChannelName = 'cn.hwato.watermark_camera/merge_overlay';

/// 传入数据拷贝到 isolate 内独立处理。
class WatermarkMergeInput {
  const WatermarkMergeInput({
    required this.photoPaths,
    required this.overlayPngBytes,
    this.jpegQuality = 88,
    this.mergeMaxLongEdge = 4320,
  });

  final List<String> photoPaths;
  final Uint8List overlayPngBytes;

  /// 1–100
  final int jpegQuality;

  /// 成片最长边像素上限，`0` 表示不缩放（更清晰但更慢）。
  final int mergeMaxLongEdge;
}

List<String> _watermarkMergeInIsolate(WatermarkMergeInput input) {
  if (input.photoPaths.isEmpty) return input.photoPaths;

  final overlayTemplate = img.decodeImage(input.overlayPngBytes);
  if (overlayTemplate == null) return input.photoPaths;

  final out = <String>[];
  final ts = DateTime.now().millisecondsSinceEpoch;
  final quality = input.jpegQuality.clamp(1, 100);

  for (var i = 0; i < input.photoPaths.length; i++) {
    final path = input.photoPaths[i];
    try {
      final raw = File(path).readAsBytesSync();
      var decoded = img.decodeImage(raw);
      if (decoded == null) {
        out.add(path);
        continue;
      }

      if (decoded.exif.imageIfd.hasOrientation &&
          (decoded.exif.imageIfd.orientation ?? 1) != 1) {
        decoded = img.bakeOrientation(decoded);
      }

      if (input.mergeMaxLongEdge > 0) {
        final mw = decoded.width;
        final mh = decoded.height;
        final longEdge = math.max(mw, mh);
        if (longEdge > input.mergeMaxLongEdge) {
          final ratio = input.mergeMaxLongEdge / longEdge;
          final nw = math.max(1, (mw * ratio).round());
          final nh = math.max(1, (mh * ratio).round());
          decoded = img.copyResize(
            decoded,
            width: nw,
            height: nh,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      final base = decoded.clone();
      final pw = base.width;
      final ph = base.height;
      final ow = overlayTemplate.width;
      final oh = overlayTemplate.height;
      if (ow < 1 || oh < 1) {
        out.add(path);
        continue;
      }

      final s = math.min(pw / ow, ph / oh);
      final nw = math.max(1, (ow * s).round());
      final nh = math.max(1, (oh * s).round());

      final scaled = (nw == ow && nh == oh)
          ? overlayTemplate
          : img.copyResize(
              overlayTemplate,
              width: nw,
              height: nh,
              interpolation: img.Interpolation.linear,
            );

      img.compositeImage(
        base,
        scaled,
        blend: img.BlendMode.alpha,
        center: true,
      );

      final jpg = img.encodeJpg(base, quality: quality);
      final file = File('${Directory.systemTemp.path}/wm_merge_${ts}_$i.jpg');
      file.writeAsBytesSync(jpg, flush: true);
      out.add(file.path);
    } catch (_) {
      out.add(path);
    }
  }
  return out;
}

Future<List<String>> _mergeNativeSequential(
  List<String> photoPaths,
  Uint8List overlayPngBytes, {
  required int jpegQuality,
  required int mergeMaxLongEdge,
}) async {
  const channel = MethodChannel(_mergeOverlayChannelName);
  final out = <String>[];
  for (var i = 0; i < photoPaths.length; i++) {
    final path = photoPaths[i];
    final merged = await channel.invokeMethod<String>(
      'mergeOverlayJpeg',
      <String, Object?>{
        'basePath': path,
        'overlayPngBytes': overlayPngBytes,
        'jpegQuality': jpegQuality.clamp(1, 100),
        'mergeMaxLongEdge': mergeMaxLongEdge < 0 ? 0 : mergeMaxLongEdge,
      },
    );
    if (merged != null && merged.isNotEmpty) {
      out.add(merged);
    } else {
      out.add(path);
    }
  }
  return out;
}

/// 将相机拍到的照片与 [overlayPngBytes]（截图 PNG，与水印区域同比例）叠在一起。
///
/// **优先走 Android / iOS 原生合成**（系统编解码 + GPU/NEON，通常比纯 Dart 快一个数量级）；
/// 失败时回退到 isolate + [image] 包。
///
/// [mergeMaxLongEdge]：限制输出最长边像素；
/// 设为 `0` 表示不缩小（仅原生合成时仍明显快于 Dart，但文件更大、略慢）。
Future<List<String>> mergePhotoPathsWithWatermarkOverlay(
  List<String> photoPaths,
  Uint8List overlayPngBytes, {
  int jpegQuality = 88,
  int mergeMaxLongEdge = 4320,
}) async {
  if (photoPaths.isEmpty) return photoPaths;
  if (overlayPngBytes.isEmpty) return photoPaths;

  final q = jpegQuality.clamp(1, 100);
  final cap = mergeMaxLongEdge < 0 ? 0 : mergeMaxLongEdge;

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      return await _mergeNativeSequential(
        photoPaths,
        overlayPngBytes,
        jpegQuality: q,
        mergeMaxLongEdge: cap,
      );
    } catch (e, st) {
      assert(() {
        debugPrint('native merge failed, fallback to isolate: $e\n$st');
        return true;
      }());
    }
  }

  final input = WatermarkMergeInput(
    photoPaths: List<String>.from(photoPaths),
    overlayPngBytes: Uint8List.fromList(overlayPngBytes),
    jpegQuality: q,
    mergeMaxLongEdge: cap,
  );

  try {
    return await Isolate.run(() => _watermarkMergeInIsolate(input));
  } catch (_) {
    return photoPaths;
  }
}
