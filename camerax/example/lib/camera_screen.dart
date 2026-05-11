import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';

import 'camerax_example_buttons.dart';

/// 演示 [CameraWidget] + overlay 的完整相机界面。
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.controller, this.previewLetterboxShift = const Offset(0, 10)});

  final CameraxController controller;

  /// 传给 [CameraWidget.previewLetterboxShift]。
  final Offset previewLetterboxShift;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraPreviewRatio _photoPreviewRatio = CameraPreviewRatio.ratio16x9;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      // extendBodyBehindAppBar: true,
      // // backgroundColor: Colors.black,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   foregroundColor: Colors.white,
      //   actions: [
      //     CameraPreviewRatioMenuButton(controller: c, photoPreviewRatio: _photoPreviewRatio, onPhotoPreviewRatioChanged: (value) => setState(() => _photoPreviewRatio = value)),
      //     CameraFlashModeButton(controller: c),
      //   ],
      // ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: c,
            builder: (_, _) => CameraWidget(
              controller: c,
              fit: BoxFit.cover,
              previewRatio: c.operationMode == CameraxOperationMode.video ? CameraPreviewRatio.ratio16x9 : _photoPreviewRatio,
              previewLetterboxShift: widget.previewLetterboxShift,
              // fullOverlayBuilder: (context, previewRect, containerSize) => _Overlay(controller: c, previewRect: previewRect, containerSize: containerSize),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                actions: [
                  CameraPreviewRatioMenuButton(
                    controller: c,
                    photoPreviewRatio: _photoPreviewRatio,
                    onPhotoPreviewRatioChanged: (value) => setState(() => _photoPreviewRatio = value),
                  ),
                  CameraFlashModeButton(controller: c),
                ],
              ),
              Expanded(child: Container()),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 45),
                    SizedBox(width: 24),
                    Expanded(child: CameraZoomCapsuleBar(controller: c)),
                    SizedBox(width: 24),
                    CameraLensSwitchButton(controller: c),
                  ],
                ),
              ),
              Row(
                children: [
                  Spacer(),
                  CameraPhotoVideoModeButton(controller: c),
                  Spacer(),
                ],
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CameraShutterButton(controller: c)],
              ),
              Container(height: 90),
            ],
          ),
        ],
      ),
    );
  }
}
