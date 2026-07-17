import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/device_key_service.dart';
import 'package:watermark_camera/utils/anti_fake_code_generator.dart';
import 'package:watermark_camera/utils/rsa_key_pair_helper.dart';

/// 在成片右下角烧录白色防伪码，并生成验真凭证。
abstract final class AntiFakeOverlay {
  /// [imageHash] 需与空间上传时的文件内容哈希（[SpaceUploadHelper.hashFileContent]）一致。
  static Future<AntiFakeProof?> applyToImagePath({
    required String imagePath,
    required String imageHash,
    required DeviceKeyService deviceKeyService,
    required AMapLocationService locationService,
    String? extraEntropy,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final proof = await buildProof(
      imageHash: imageHash,
      claimedWidth: decoded.width,
      claimedHeight: decoded.height,
      deviceKeyService: deviceKeyService,
      locationService: locationService,
      extraEntropy: extraEntropy,
    );
    if (proof == null) return null;

    _drawAntiFakeCode(decoded, proof.antiFakeCode);
    await file.writeAsBytes(img.encodeJpg(decoded, quality: 95), flush: true);
    return proof;
  }

  /// 按拍照规则生成验真凭证（不改写图片像素）。
  static Future<AntiFakeProof?> buildProof({
    required String imageHash,
    required int claimedWidth,
    required int claimedHeight,
    required DeviceKeyService deviceKeyService,
    required AMapLocationService locationService,
    String? extraEntropy,
  }) async {
    final ready = await deviceKeyService.ensureKeysReady();
    if (!ready) return null;

    final deviceId = deviceKeyService.deviceId;
    final privateKey = deviceKeyService.privateKeyBase64;
    if (deviceId == null ||
        deviceId.isEmpty ||
        privateKey == null ||
        privateKey.isEmpty) {
      return null;
    }

    final hash = imageHash.trim();
    if (hash.isEmpty) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final location = locationService.latestLocation.value;
    final latitude = location?.latitude;
    final longitude = location?.longitude;
    final hasGps = latitude != null && longitude != null;
    final locationSource = hasGps ? 'GPS' : 'NONE';
    final lat = hasGps ? latitude : 0.0;
    final lng = hasGps ? longitude : 0.0;

    // 与上传/验真一致：antiFakeCode = AntiFakeCodeGenerator.generate(imageHash)
    final antiFakeCode = AntiFakeCodeGenerator.generate(hash);
    final signature = RsaKeyPairHelper.signSha256Base64(
      privateKeyBase64: privateKey,
      message: antiFakeCode,
    );

    return AntiFakeProof(
      imageHash: hash,
      antiFakeCode: antiFakeCode,
      signature: signature,
      timestamp: timestamp,
      latitude: lat,
      longitude: lng,
      locationSource: locationSource,
      deviceId: deviceId,
      claimedWidth: claimedWidth,
      claimedHeight: claimedHeight,
      extraEntropy: extraEntropy,
    );
  }

  static void _drawAntiFakeCode(img.Image image, String code) {
    final font = image.width >= 2400
        ? img.arial48
        : (image.width >= 1200 ? img.arial24 : img.arial14);
    final marginX = (image.width * 0.025).round().clamp(8, 48);
    final marginY = (image.height * 0.025).round().clamp(8, 48);
    final y = (image.height - marginY - font.lineHeight).clamp(0, image.height - 1);

    img.drawString(
      image,
      code,
      font: font,
      x: image.width - marginX,
      y: y,
      color: img.ColorRgb8(255, 255, 255),
      rightJustify: true,
    );
  }
}
