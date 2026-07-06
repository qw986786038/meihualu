import 'dart:async';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/pages/camera/camera_map_controller.dart';
import 'package:watermark_camera/pages/camera/image_tagging_flow.dart';
import 'package:watermark_camera/pages/camera/screen_text_recognition_flow.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/aliyun_image_tagging_service.dart';
import 'package:watermark_camera/services/aliyun_ocr_service.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/widgets/camera_bottom_bar.dart';
import 'package:watermark_camera/widgets/camera_map_overlay.dart';
import 'package:watermark_camera/widgets/camera_map_settings_sheet.dart';
import 'package:watermark_camera/widgets/camerax_buttons.dart';
import 'package:watermark_camera/widgets/gallery_preview_button.dart';
import 'package:watermark_camera/widgets/stack_board.dart';
import 'package:watermark_camera/widgets/work_mode_bar.dart';

import '../widgets/WaterMarkButton.dart';
import 'WaterMark/WaterMarkSelectPage.dart';
import 'camera/CameraController.dart';
import 'camera/WaterMarkController.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraPreviewRatio _photoPreviewRatio = CameraPreviewRatio.ratio3x4;

  CameraController cameraController = Get.put(CameraController());
  WaterMarkController waterMarkController = Get.put(WaterMarkController());
  final CameraMapController cameraMapController = Get.put(CameraMapController());
  final AMapLocationService locationService = Get.find<AMapLocationService>();
  final AliyunImageTaggingService taggingService =
      Get.find<AliyunImageTaggingService>();
  final AliyunOcrService ocrService = Get.find<AliyunOcrService>();

  bool _didAddDefaultWatermark = false;
  bool _isTaggingRecognizing = false;
  bool _isScreenTextRecognizing = false;

  void _ensureDefaultWatermarkAfterPreview(Size size) {
    if (_didAddDefaultWatermark) return;
    if (size.width <= 0 || size.height <= 0) return;
    _didAddDefaultWatermark = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      waterMarkController.addWaterMark();
    });
  }

  Future<void> _openMapSettingsSheet() async {
    if (!mounted) return;
    await showCameraMapSettingsSheet(context);
  }

  Future<void> _openWatermarkSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.55,
          child: const WaterMarkSelectPage(),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openImageTagging() async {
    final action = await context.push<String?>(AppPaths.imageTagging);
    if (!mounted || action != kImageTaggingCaptureAction) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('请对准目标后拍照识别'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: '立即识别',
            onPressed: () => unawaited(_runCaptureTagging()),
          ),
        ),
      );
  }

  Future<void> _runCaptureTagging() async {
    if (_isTaggingRecognizing) return;
    setState(() => _isTaggingRecognizing = true);
    try {
      await captureAndRecognizeFromCamera(
        context: context,
        cameraController: cameraController,
        taggingService: taggingService,
        onError: _showSnack,
      );
    } finally {
      if (mounted) setState(() => _isTaggingRecognizing = false);
    }
  }

  Future<void> _openScreenTextOcr() async {
    final action = await context.push<String?>(AppPaths.screenTextOcr);
    if (!mounted || action != kScreenTextCaptureAction) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('请对准 LED 广告屏后拍照识别'),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: '立即识别',
            onPressed: () => unawaited(_runCaptureScreenText()),
          ),
        ),
      );
  }

  Future<void> _runCaptureScreenText() async {
    if (_isScreenTextRecognizing) return;
    setState(() => _isScreenTextRecognizing = true);
    try {
      await captureAndRecognizeScreenText(
        context: context,
        cameraController: cameraController,
        ocrService: ocrService,
        onError: _showSnack,
      );
    } finally {
      if (mounted) setState(() => _isScreenTextRecognizing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(locationService.warmupLocation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(cameraController.refreshLatestPhotoPreview());
      unawaited(locationService.refreshLocation());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: cameraController.camera,
            builder: (_, _) => CameraWidget(
              controller: cameraController.camera,
              fit: BoxFit.cover,
              previewRatio:
                  cameraController.camera.operationMode ==
                      CameraxOperationMode.video
                  ? CameraPreviewRatio.ratio16x9
                  : _photoPreviewRatio,
              previewLetterboxShift: const Offset(0, 10),
              overlayBuilder: (context, size) {
                _ensureDefaultWatermarkAfterPreview(size);
                return AnimatedContainer(
                  width: size.width,
                  height: size.height,
                  duration: Duration(milliseconds: 200),

                  ///水印面板
                  child: Screenshot(
                    controller: cameraController.screenshotController,
                    child: Stack(
                      children: [
                        StackBoard(
                          keepEdgeAnchoredOnResize: true,
                          pointerEventsThroughEmptyOnly: true,
                          backgroundColor: Colors.transparent,
                          outerGap: 4,
                          controller: waterMarkController.controller,
                        ),
                        CameraMapOverlay(
                          previewSize: size,
                          onTap: _openMapSettingsSheet,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                actions: [
                  Obx(
                    () => IconButton(
                      tooltip: '地图',
                      onPressed: _openMapSettingsSheet,
                      icon: Icon(
                        Icons.map_outlined,
                        color: cameraMapController.mapEnabled.value
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                  CameraPreviewRatioMenuButton(
                    controller: cameraController.camera,
                    photoPreviewRatio: _photoPreviewRatio,
                    onPhotoPreviewRatioChanged: (value) =>
                        setState(() => _photoPreviewRatio = value),
                  ),
                  CameraFlashModeButton(controller: cameraController.camera),
                ],
              ),
              CameraRecordingTimerBadge(controller: cameraController.camera),
              Expanded(child: Container()),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 45),
                    SizedBox(width: 24),
                    Expanded(
                      child: CameraZoomCapsuleBar(
                        controller: cameraController.camera,
                      ),
                    ),
                    SizedBox(width: 24),
                    CameraLensSwitchButton(controller: cameraController.camera),
                  ],
                ),
              ),
              Row(
                children: [
                  Spacer(),
                  CameraPhotoVideoModeButton(
                    controller: cameraController.camera,
                  ),
                  Spacer(),
                ],
              ),
              const WorkModeBar(),
              Container(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(
                      () => GalleryPreviewButton(
                        width: 60,
                        height: 60,
                        previewImage:
                            cameraController.latestPhotoPreviewImage.value,
                        onTap: () =>
                            unawaited(cameraController.openLatestMedia(context)),
                      ),
                    ),
                    Spacer(),
                    CameraShutterButton(
                      controller: cameraController.camera,
                      onStartVideoRecording:
                          cameraController.startVideoRecording,
                      onStopVideoRecording: cameraController.stopVideoRecording,
                    ),
                    Spacer(),
                    WaterMarkButton(
                      width: 60,
                      height: 60,
                      onTap: () {
                        _openWatermarkSheet();
                      },
                    ),
                  ],
                ),
              ),
              CameraBottomBar(
                items: [
                  CameraBottomBarItem(
                    icon: Icons.photo_camera_outlined,
                    label: '拍照',
                    selected: true,
                    onTap: () {},
                  ),
                  CameraBottomBarItem(
                    icon: Icons.photo_library_outlined,
                    label: '照片编辑',
                    onTap: () => context.push(AppPaths.mediaGallery),
                  ),
                  CameraBottomBarItem(
                    icon: Icons.document_scanner_outlined,
                    label: '图像识别',
                    onTap: () => unawaited(_openImageTagging()),
                  ),
                  CameraBottomBarItem(
                    icon: Icons.text_fields_outlined,
                    label: '屏幕文字识别',
                    onTap: () => unawaited(_openScreenTextOcr()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (_isTaggingRecognizing || _isScreenTextRecognizing)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _isScreenTextRecognizing
                            ? '正在识别屏幕文字...'
                            : '正在识别...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
