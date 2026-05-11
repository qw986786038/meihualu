import 'dart:async' show unawaited;
import 'dart:io';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';

class CameraController extends GetxController {
  static const MethodChannel _cameraxChannel = MethodChannel('camerax');
  final camera = CameraxController();
  final screenshotController = ScreenshotController();
  final Rxn<ImageProvider> latestPhotoPreviewImage = Rxn<ImageProvider>();
  static const _albumName = '水印相机';

  Future<AssetEntity?> getLatestPhoto() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
    if (albums.isEmpty) return null;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return null;
    return assets.first;
  }

  @override
  Future<void> onInit() async {
    camera.onCaptured = (file, type) {
      unawaited(_handleCapture(file, type));
    };
    await camera.initialize();
    unawaited(refreshLatestPhotoPreview());
    super.onInit();
  }

  Future<void> refreshLatestPhotoPreview() async {
    final latest = await getLatestPhoto();
    if (latest == null) {
      latestPhotoPreviewImage.value = null;
      return;
    }
    var thumb = await latest.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 85,
    );
    if (thumb == null && latest.type == AssetType.video) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      thumb = await latest.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
        quality: 85,
      );
    }
    latestPhotoPreviewImage.value = thumb == null ? null : MemoryImage(thumb);
  }

  Future<void> _handleCapture(XFile file, CameraxCaptureType type) async {
    if (type == CameraxCaptureType.photo) {
      final merged = await _mergePhotoWithWatermark(file);
      await _saveToGallery(merged ?? file, type);
    } else {
      await _saveToGallery(file, type);
    }
    await refreshLatestPhotoPreview();
  }

  Future<XFile?> _mergePhotoWithWatermark(XFile photoFile) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final watermarkBytes = await screenshotController.capture(
        delay: const Duration(milliseconds: 30),
        pixelRatio: 2.0,
      );
      if (watermarkBytes == null || watermarkBytes.isEmpty) return null;

      final outPath = _buildWatermarkedPath(photoFile.path);
      var ok = await _cameraxChannel
          .invokeMethod<bool>('mergeCaptureWithOverlay', <String, dynamic>{
            'inputPath': photoFile.path,
            'overlayBytes': watermarkBytes,
            'outputPath': outPath,
            'quality': 95,
          });
      if (ok != true) {
        ok = await _mergeWithDart(photoFile.path, watermarkBytes, outPath);
      }
      if (ok != true || !await File(outPath).exists()) return null;
      return XFile(outPath);
    } catch (_) {
      return null;
    }
  }

  String _buildWatermarkedPath(String sourcePath) {
    final dot = sourcePath.lastIndexOf('.');
    if (dot <= 0) return '${sourcePath}_watermarked.jpg';
    final base = sourcePath.substring(0, dot);
    final ext = sourcePath.substring(dot);
    return '${base}_watermarked$ext';
  }

  Future<bool> _mergeWithDart(
    String inputPath,
    Uint8List overlayBytes,
    String outputPath,
  ) async {
    try {
      final baseBytes = await File(inputPath).readAsBytes();
      final baseImage = img.decodeImage(baseBytes);
      final overlayImage = img.decodeImage(overlayBytes);
      if (baseImage == null || overlayImage == null) return false;
      final resizedOverlay = img.copyResize(
        overlayImage,
        width: baseImage.width,
        height: baseImage.height,
        interpolation: img.Interpolation.linear,
      );
      img.compositeImage(baseImage, resizedOverlay);
      await File(
        outputPath,
      ).writeAsBytes(img.encodeJpg(baseImage, quality: 95), flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveToGallery(XFile file, CameraxCaptureType type) async {
    await GallerySaver.savePath(
      file.path,
      isVideo: type == CameraxCaptureType.video,
      album: _albumName,
    );
  }

  @override
  void onClose() {
    camera.dispose();
    super.onClose();
  }
}
