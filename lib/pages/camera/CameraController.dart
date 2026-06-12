import 'dart:async' show Timer, unawaited;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:watermark_camera/pages/gallery/latest_media_preview_page.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:image/image.dart' as img;
import 'package:native_exif/native_exif.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/pages/camera/WaterMarkController.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/photo_sync_service.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/utils/watermark_original_store.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

class CameraController extends GetxController {
  static const MethodChannel _cameraxChannel = MethodChannel('camerax');
  final camera = CameraxController();
  final screenshotController = ScreenshotController();
  final Rxn<ImageProvider> latestPhotoPreviewImage = Rxn<ImageProvider>();
  final AMapLocationService _locationService = Get.find<AMapLocationService>();
  static const _albumName = '水印相机';
  Timer? _videoWatermarkTimer;

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

  Future<void> startVideoRecording() async {
    _videoWatermarkTimer?.cancel();
    await camera.startVideoRecording(
      watermarkOverlayProvider: () => _captureWatermarkBytes(forVideo: true),
    );
    _videoWatermarkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshRecordingWatermarkOverlay());
    });
    unawaited(_refreshRecordingWatermarkOverlay());
  }

  Future<void> stopVideoRecording() async {
    _videoWatermarkTimer?.cancel();
    _videoWatermarkTimer = null;
    await camera.stopVideoRecording();
  }

  Future<void> _refreshRecordingWatermarkOverlay() async {
    final bytes = await _captureWatermarkBytes(forVideo: true);
    if (bytes == null) return;
    await camera.updateRecordingWatermarkOverlay(bytes);
  }

  Future<void> openLatestMedia(BuildContext context) async {
    final asset = await getLatestPhoto();
    if (asset == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无照片或视频，或相册权限未授予')),
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => LatestMediaPreviewPage(asset: asset),
      ),
    );
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
    XFile output = file;
    if (type == CameraxCaptureType.photo) {
      final originalId = await WatermarkOriginalStore.saveFromPath(file.path);
      final merged = await _mergePhotoWithWatermark(file);
      output = merged ?? file;
      await _writeLocationExif(output.path);
      await _writeWatermarkMeta(output.path, originalId: originalId);
    }

    PhotoSyncResult? syncResult;
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn.value && Get.isRegistered<PhotoSyncService>()) {
        syncResult = await Get.find<PhotoSyncService>().syncCapture(
          output.path,
          isVideo: type == CameraxCaptureType.video,
          location: _locationService.watermarkAddress.value,
        );
      }
    }

    final skipLocalSave = Get.isRegistered<AuthService>() &&
        Get.find<AuthService>().skipLocalSaveAfterSync.value &&
        (syncResult?.anySuccess ?? false);

    if (!skipLocalSave) {
      await _saveToGallery(output, type);
    }
    await refreshLatestPhotoPreview();
  }

  Future<Uint8List?> _captureWatermarkBytes({bool forVideo = false}) async {
    await WidgetsBinding.instance.endOfFrame;
    if (forVideo) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await WidgetsBinding.instance.endOfFrame;
    }
    final watermarkBytes = await screenshotController.capture(
      delay: Duration(milliseconds: forVideo ? 120 : 30),
      pixelRatio: forVideo ? 1.0 : 2.0,
    );
    if (watermarkBytes == null || watermarkBytes.isEmpty) return null;
    if (!forVideo && !_hasVisibleOverlayPixels(watermarkBytes)) return null;
    return watermarkBytes;
  }

  bool _hasVisibleOverlayPixels(Uint8List pngBytes) {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return false;
    final stepX = max(1, decoded.width ~/ 24);
    final stepY = max(1, decoded.height ~/ 24);
    for (var y = 0; y < decoded.height; y += stepY) {
      for (var x = 0; x < decoded.width; x += stepX) {
        final alpha = decoded.getPixel(x, y).a;
        if (alpha > 12) return true;
      }
    }
    return false;
  }

  Future<XFile?> _mergePhotoWithWatermark(XFile photoFile) async {
    try {
      final watermarkBytes = await _captureWatermarkBytes();
      if (watermarkBytes == null) return null;

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

  Future<void> _writeWatermarkMeta(
    String imagePath, {
    String? originalId,
  }) async {
    if (!Get.isRegistered<WaterMarkController>()) return;
    final wmController = Get.find<WaterMarkController>();
    StackBoardItem? item;
    for (final candidate in wmController.controller.items) {
      if (candidate.template.templateId == 'WaterMark') {
        item = candidate;
        break;
      }
    }
    if (item == null) return;

    final boardSize = wmController.controller.boardSize;
    if (boardSize.width <= 0 || boardSize.height <= 0) return;

    await WatermarkMetadata.writeToImagePath(
      imagePath,
      data: Map<String, dynamic>.from(item.data),
      rect: item.rect,
      boardSize: boardSize,
      originalId: originalId,
    );
  }

  Future<void> _writeLocationExif(String imagePath) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    final location = _locationService.latestLocation.value;
    final latitude = location?.latitude;
    final longitude = location?.longitude;
    if (latitude == null || longitude == null) return;
    final wgs84 = _gcj02ToWgs84(latitude, longitude);

    final lowerPath = imagePath.toLowerCase();
    if (!(lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg'))) return;

    Exif? exif;
    try {
      exif = await Exif.fromPath(imagePath);
      await exif.writeAttributes(<String, Object>{
        'GPSLatitude': wgs84.$1.toString(),
        'GPSLongitude': wgs84.$2.toString(),
      });
    } catch (e, st) {
      assert(() {
        debugPrint('write GPS exif failed: $e\n$st');
        return true;
      }());
    } finally {
      await exif?.close();
    }
  }

  (double, double) _gcj02ToWgs84(double latitude, double longitude) {
    if (_isOutOfChina(latitude, longitude)) {
      return (latitude, longitude);
    }

    final delta = _delta(latitude, longitude);
    return (latitude - delta.$1, longitude - delta.$2);
  }

  (double, double) _delta(double latitude, double longitude) {
    const a = 6378245.0;
    const ee = 0.00669342162296594323;
    final dLat = _transformLatitude(longitude - 105.0, latitude - 35.0);
    final dLon = _transformLongitude(longitude - 105.0, latitude - 35.0);
    final radLat = latitude / 180.0 * pi;
    var magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    final sqrtMagic = sqrt(magic);

    final mgLat =
        (dLat * 180.0) / (((a * (1 - ee)) / (magic * sqrtMagic)) * pi);
    final mgLon = (dLon * 180.0) / ((a / sqrtMagic) * cos(radLat) * pi);
    return (mgLat, mgLon);
  }

  double _transformLatitude(double x, double y) {
    var ret =
        -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  double _transformLongitude(double x, double y) {
    var ret =
        300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret +=
        (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }

  bool _isOutOfChina(double latitude, double longitude) {
    return longitude < 72.004 ||
        longitude > 137.8347 ||
        latitude < 0.8293 ||
        latitude > 55.8271;
  }

  @override
  void onClose() {
    _videoWatermarkTimer?.cancel();
    camera.dispose();
    super.onClose();
  }
}
