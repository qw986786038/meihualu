import 'dart:io';

import 'package:getx_plus/getx_plus.dart';
import 'package:image/image.dart' as img;
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/device_key_service.dart';
import 'package:watermark_camera/utils/anti_fake_code_generator.dart';
import 'package:watermark_camera/utils/anti_fake_overlay.dart';
import 'package:watermark_camera/utils/space_upload_helper.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

/// 验真前本地鉴别，以及按拍照规则重新生成 proof。
abstract final class MediaVerifyPrepare {
  static const unsupportedMessage = '仅支持验证带水印和防伪码的照片';

  static bool hasAppWatermark(WatermarkParsedMeta? meta) {
    if (meta == null) return false;
    final originalId = meta.originalId?.trim();
    if (originalId != null && originalId.isNotEmpty) return true;
    return meta.data.containsKey(kWatermarkDataTemplateId);
  }

  static bool hasValidProof(AntiFakeProof? proof) {
    final code = proof?.antiFakeCode.trim() ?? '';
    return code.isNotEmpty;
  }

  /// 本地鉴别：须同时拿到水印与防伪凭证，缺一则不支持验真。
  /// 当前已屏蔽，恢复时取消注释并在选择/验真流程中调用。
  static Future<bool> isSupported(String imagePath) async {
    // final meta = await WatermarkMetadata.readFromImagePath(imagePath);
    // return hasAppWatermark(meta) && hasValidProof(meta?.proof);
    return true;
  }

  /// 按文件内容 SHA256 重新生成 proof（防伪码规则与后端一致）。
  static Future<AntiFakeProof?> rebuildProof(String imagePath) async {
    if (!Get.isRegistered<DeviceKeyService>() ||
        !Get.isRegistered<AMapLocationService>()) {
      return null;
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // imageHash = 文件内容 SHA256；antiFakeCode = generate(imageHash)
    final imageHash = await SpaceUploadHelper.hashFileContent(imagePath);
    return AntiFakeOverlay.buildProof(
      imageHash: imageHash,
      claimedWidth: decoded.width,
      claimedHeight: decoded.height,
      deviceKeyService: Get.find<DeviceKeyService>(),
      locationService: Get.find<AMapLocationService>(),
    );
  }
}
