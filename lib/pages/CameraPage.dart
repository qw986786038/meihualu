import 'dart:async';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/widgets/camera_bottom_bar.dart';
import 'package:watermark_camera/widgets/camerax_buttons.dart';
import 'package:watermark_camera/widgets/gallery_preview_button.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

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
  final AMapLocationService locationService = Get.find<AMapLocationService>();

  bool _didAddDefaultWatermark = false;

  void _ensureDefaultWatermarkAfterPreview(Size size) {
    if (_didAddDefaultWatermark) return;
    if (size.width <= 0 || size.height <= 0) return;
    _didAddDefaultWatermark = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      waterMarkController.addWaterMark();
    });
  }

  Future<void> _openWatermarkSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: WaterMarkSelectPage(),
        );
      },
    );
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
                    child: StackBoard(
                      keepEdgeAnchoredOnResize: true,
                      pointerEventsThroughEmptyOnly: true,
                      backgroundColor: Colors.transparent,

                      outerGap: 4,
                      controller: waterMarkController.controller,
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
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
