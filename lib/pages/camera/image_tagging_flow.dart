import 'dart:typed_data';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/camera/CameraController.dart';
import 'package:watermark_camera/pages/camera/image_tagging_result_sheet.dart';
import 'package:watermark_camera/services/aliyun_image_tagging_service.dart';

Future<void> recognizeImageBytes({
  required BuildContext context,
  required AliyunImageTaggingService taggingService,
  required Uint8List bytes,
  AssetEntity? asset,
  Uint8List? previewBytes,
  required ValueChanged<String> onError,
}) async {
  if (!taggingService.isConfigured) {
    onError('请配置阿里云 AccessKey（ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET）');
    return;
  }

  try {
    final tags = await taggingService.tagImageBytes(bytes);
    if (!context.mounted) return;
    await showImageTaggingResultSheet(
      context: context,
      tags: tags,
      previewBytes: previewBytes ?? bytes,
      asset: asset,
    );
  } on AliyunImageTaggingException catch (e) {
    onError(e.message);
  } catch (_) {
    onError('识别失败，请稍后重试');
  }
}

Future<void> captureAndRecognizeFromCamera({
  required BuildContext context,
  required CameraController cameraController,
  required AliyunImageTaggingService taggingService,
  required ValueChanged<String> onError,
}) async {
  if (!taggingService.isConfigured) {
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

  await recognizeImageBytes(
    context: context,
    taggingService: taggingService,
    bytes: bytes,
    onError: onError,
  );
}

const String kImageTaggingCaptureAction = 'capture';
