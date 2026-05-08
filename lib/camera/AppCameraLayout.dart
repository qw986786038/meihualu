// ignore_for_file: unused_import

import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/src/orchestrator/states/states.dart';
import 'package:camerawesome/src/widgets/awesome_camera_mode_selector.dart';
import 'package:camerawesome/src/widgets/camera_awesome_builder.dart';
import 'package:camerawesome/src/widgets/filters/awesome_filter_widget.dart';
import 'package:camerawesome/src/widgets/layout/layout.dart';
import 'package:camerawesome/src/widgets/utils/awesome_theme.dart';
import 'package:camerawesome/src/widgets/zoom/awesome_zoom_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:watermark_camera/camera/AppCameraAspectRatioButton.dart';
import 'package:watermark_camera/camera/AppCameraCaptureButton.dart';
import 'package:watermark_camera/camera/AppCameraFlashButton.dart';
import 'package:watermark_camera/camera/AppCameraLocationButton.dart';
import 'package:watermark_camera/camera/AppCameraMediaPreview.dart';
import 'package:watermark_camera/camera/AppCameraModeSelector.dart';
import 'package:watermark_camera/camera/AppCameraSwitchButton.dart';

import '../CameraWidget.dart';
import 'AppFilterWidget.dart';
import 'AppZoomSelector.dart';

/// This widget doesn't handle [PreparingCameraState]
class AppCameraLayout extends StatelessWidget {
  final CameraState state;
  final AppBodyBuilder? body;

  const AppCameraLayout({super.key, required this.state, this.body});

  @override
  Widget build(BuildContext context) {
    final theme = AwesomeThemeProvider.of(context).theme;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(child: body?.call(state) ?? Container()),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppCameraCaptureButton(state: state),
                (state is VideoRecordingCameraState
                    ? const SizedBox(width: 48)
                    : StreamBuilder<MediaCapture?>(
                        stream: state.captureState$,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(width: 60, height: 60);
                          }
                          return SizedBox(
                            width: 60,
                            child: AppCameraMediaPreview(mediaCapture: snapshot.requireData, onMediaTap: (media) {}),
                          );
                        },
                      )),
              ],
            ),
          ),
          AppCameraModeSelector(state: state),
        ],
      ),
    );
  }
}
