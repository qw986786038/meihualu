import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import 'camera/AppCameraCaptureButton.dart';
import 'camera/AppCameraMediaPreview.dart';
import 'camera/AppCameraModeSelector.dart';

typedef AppCameraBuilder = Widget Function(CameraState state, double previewWidth, double previewHeight);
typedef AppBodyBuilder = Widget Function(CameraState state);
typedef CapturePathProcessor = Future<List<String>> Function(MediaCapture event, List<String> paths);
typedef WatermarkTapCallback = Future<void> Function();

class CameraWidget extends StatefulWidget {
  const CameraWidget({
    super.key,
    this.previewPadding = EdgeInsets.zero,
    this.builder,
    this.body,
    this.onBeforeSaveToGallery,
    this.onWatermarkTap,
  });

  final AppCameraBuilder? builder;
  final AppBodyBuilder? body;
  final EdgeInsets previewPadding;
  /// Optional hook: process/replace captured files before gallery save.
  /// Return final file paths to save (can be original paths or processed outputs).
  final CapturePathProcessor? onBeforeSaveToGallery;
  /// Optional callback triggered when watermark button is tapped.
  final WatermarkTapCallback? onWatermarkTap;

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  static const _albumName = '水印相机';

  List<String> _collectPaths(CaptureRequest request) {
    return request.when(
      single: (s) {
        final p = s.file?.path;
        return p != null ? <String>[p] : <String>[];
      },
      multiple: (m) => [
        for (final f in m.fileBySensor.values)
          if (f?.path != null) f!.path,
      ],
    );
  }

  Future<void> _saveToGallery(MediaCapture event) async {
    if (event.status != MediaCaptureStatus.success) return;
    var paths = _collectPaths(event.captureRequest);
    if (paths.isEmpty) return;
    if (widget.onBeforeSaveToGallery != null) {
      paths = await widget.onBeforeSaveToGallery!(event, paths);
      if (paths.isEmpty) return;
    }
    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) return;
    for (final path in paths) {
      if (event.isVideo) {
        await Gal.putVideo(path, album: _albumName);
      } else {
        await Gal.putImage(path, album: _albumName);
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CameraAwesomeBuilder.custom(
        previewPadding: widget.previewPadding,
        previewAlignment: Alignment.topCenter,
        sensorConfig: SensorConfig.single(sensor: Sensor.position(SensorPosition.back)),
        builder: (cameraModeState, preview) {
          final previewWidth = preview.nativePreviewSize.width * preview.scale - widget.previewPadding.left - widget.previewPadding.right;
          final previewHeight = preview.nativePreviewSize.height * preview.scale - widget.previewPadding.top - widget.previewPadding.bottom;
          return Stack(
            children: [
              // AppCameraLayout(state: cameraModeState, body: widget.body),
              widget.builder?.call(cameraModeState, previewHeight, previewHeight) ?? Container(),

              Column(
                children: [
                  Container(height: widget.previewPadding.top),
                  AnimatedContainer(duration: Duration(milliseconds: 200), width: previewWidth, height: previewHeight),

                  Expanded(child: Container(color: Colors.white)),
                ],
              ),
              Column(
                children: [
                  Expanded(child: widget.body?.call(cameraModeState) ?? Container()),
                  Container(
                    height: 250,
                    child: Column(
                      children: [
                        Expanded(child: Container()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Spacer(),
                            (cameraModeState is VideoRecordingCameraState
                                ? const SizedBox(width: 48)
                                : StreamBuilder<MediaCapture?>(
                                    stream: cameraModeState.captureState$,
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
                            Spacer(),
                            AppCameraCaptureButton(state: cameraModeState),
                            Spacer(),
                            GestureDetector(
                              onTap: () async {
                                await widget.onWatermarkTap?.call();
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black38, width: 2),
                                ),
                                child: const Text("水印", style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        AppCameraModeSelector(state: cameraModeState),
                        Container(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        saveConfig: SaveConfig.photoAndVideo(exifPreferences: ExifPreferences(saveGPSLocation: true)),
        previewFit: CameraPreviewFit.contain,
        onMediaCaptureEvent: (event) => unawaited(_saveToGallery(event)),
      ),
    );
  }
}
