import 'dart:typed_data';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/camera/CameraController.dart';
import 'package:watermark_camera/pages/camera/screen_text_result_sheet.dart';
import 'package:watermark_camera/services/aliyun_ocr_service.dart';

Future<void> recognizeScreenTextBytes({
  required BuildContext context,
  required AliyunOcrService ocrService,
  required Uint8List bytes,
  AssetEntity? asset,
  Uint8List? previewBytes,
  required ValueChanged<String> onError,
}) async {
  if (!ocrService.isConfigured) {
    onError('请配置阿里云 AccessKey（ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET）');
    return;
  }

  try {
    final result = await ocrService.recognizeImageBytes(bytes);
    if (!context.mounted) return;
    await showScreenTextResultSheet(
      context: context,
      result: result,
      previewBytes: previewBytes ?? bytes,
      asset: asset,
    );
  } on AliyunOcrException catch (e) {
    onError(e.message);
  } catch (_) {
    onError('屏幕文字识别失败，请稍后重试');
  }
}

Future<void> captureAndRecognizeScreenText({
  required BuildContext context,
  required CameraController cameraController,
  required AliyunOcrService ocrService,
  required ValueChanged<String> onError,
}) async {
  if (!ocrService.isConfigured) {
    onError('请配置阿里云 AccessKey（ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET）');
    return;
  }

  if (cameraController.camera.operationMode == CameraxOperationMode.video) {
    onError('请先切换到拍照模式');
    return;
  }
  if (cameraController.camera.isRecording) {
    onError('请先停止录像');
    return;
  }

  final bytes = await cameraController.capturePhotoBytesForTagging();
  if (!context.mounted) return;
  if (bytes == null) {
    onError('拍照失败，请重试');
    return;
  }

  await recognizeScreenTextBytes(
    context: context,
    ocrService: ocrService,
    bytes: bytes,
    onError: onError,
  );
}

const String kScreenTextCaptureAction = 'capture';
