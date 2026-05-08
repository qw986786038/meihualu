import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';

/// 默认：拍摄成功后删除临时文件（不入相册）。
void discardCaptureTempFiles(MediaCapture event) {
  if (event.status != MediaCaptureStatus.success) return;
  final paths = event.captureRequest.when(
    single: (s) {
      final p = s.file?.path;
      return p != null ? <String>[p] : <String>[];
    },
    multiple: (m) => [
      for (final f in m.fileBySensor.values)
        if (f?.path != null) f!.path,
    ],
  );
  for (final p in paths) {
    try {
      final file = File(p);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}

String aspectRatioLabel(CameraAspectRatios ratio) {
  switch (ratio) {
    case CameraAspectRatios.ratio_16_9:
      return '16 : 9';
    case CameraAspectRatios.ratio_4_3:
      return '4 : 3';
    case CameraAspectRatios.ratio_1_1:
      return '1 : 1';
  }
}

CameraAspectRatios nextAspectRatio(CameraAspectRatios current) {
  if (Platform.isIOS) {
    switch (current) {
      case CameraAspectRatios.ratio_16_9:
        return CameraAspectRatios.ratio_4_3;
      case CameraAspectRatios.ratio_4_3:
        return CameraAspectRatios.ratio_1_1;
      case CameraAspectRatios.ratio_1_1:
        return CameraAspectRatios.ratio_16_9;
    }
  }
  return current == CameraAspectRatios.ratio_16_9
      ? CameraAspectRatios.ratio_4_3
      : CameraAspectRatios.ratio_16_9;
}

/// 控制 [CameraWidget2]：切换模式、比例、快门、同步底层 [CameraState]。
///
/// 由外层创建并在 [dispose] 时释放；[CameraWidget2] 只负责在每帧调用 [syncCameraState]。
final class CameraWidgetController extends ChangeNotifier {
  CameraState? _cameraState;
  bool _capturingPhoto = false;
  bool _changingAspectRatio = false;

  CameraState? get cameraState => _cameraState;
  bool get capturingPhoto => _capturingPhoto;
  bool get changingAspectRatio => _changingAspectRatio;
  bool get isReady => _cameraState != null;

  void syncCameraState(CameraState state) {
    if (!identical(_cameraState, state)) {
      _cameraState = state;
      notifyListeners();
    }
  }

  void setCaptureMode(CaptureMode mode) {
    final s = _cameraState;
    if (s == null) return;
    if (s is VideoRecordingCameraState) return;
    s.setState(mode);
    notifyListeners();
  }

  Future<void> cycleAspectRatio() async {
    final state = _cameraState;
    if (state == null || _changingAspectRatio) return;
    _changingAspectRatio = true;
    notifyListeners();
    final cfg = state.sensorConfig;
    final next = nextAspectRatio(cfg.aspectRatio);
    try {
      await cfg.setAspectRatio(next);
    } finally {
      _changingAspectRatio = false;
      notifyListeners();
    }
  }

  Future<void> shutter() async {
    final state = _cameraState;
    if (state == null) return;
    await state.when(
      onPhotoMode: (photo) async {
        if (_capturingPhoto) return;
        _capturingPhoto = true;
        notifyListeners();
        try {
          await photo.takePhoto();
        } finally {
          _capturingPhoto = false;
          notifyListeners();
        }
      },
      onVideoMode: (video) async {
        await video.startRecording();
        notifyListeners();
      },
      onVideoRecordingMode: (rec) async {
        await rec.stopRecording();
        notifyListeners();
      },
      onPreparingCamera: (_) async {},
      onPreviewMode: (_) async {},
      onAnalysisOnlyMode: (_) async {},
    );
  }

}

/// 封装 CamerAwesome 预览与极简控制栏；通过 [CameraWidgetController] 在外部或在子树中触发操作。
class CameraWidget2 extends StatelessWidget {
  const CameraWidget2({
    super.key,
    required this.controller,
    this.onClose,
    this.onMediaCaptureEvent = discardCaptureTempFiles,
    this.initialCaptureMode = CaptureMode.photo,
    this.previewFit = CameraPreviewFit.contain,
    this.sensorConfig,
  });

  final CameraWidgetController controller;
  final VoidCallback? onClose;
  final void Function(MediaCapture event)? onMediaCaptureEvent;

  /// 与控制器配合的初始采集模式。
  final CaptureMode initialCaptureMode;
  final CameraPreviewFit previewFit;
  final SensorConfig? sensorConfig;

  SaveConfig _saveConfig() =>
      SaveConfig.photoAndVideo(initialCaptureMode: initialCaptureMode);

  @override
  Widget build(BuildContext context) {
    return CameraAwesomeBuilder.custom(
      saveConfig: _saveConfig(),
      previewFit: previewFit,
      sensorConfig: sensorConfig ??
          SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back),
            flashMode: FlashMode.none,
            aspectRatio: CameraAspectRatios.ratio_4_3,
          ),
      enablePhysicalButton: false,
      onMediaCaptureEvent: onMediaCaptureEvent,
      builder: (state, _) {
        controller.syncCameraState(state);
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _CameraChrome(
            controller: controller,
            state: state,
            onClose: onClose,
          ),
        );
      },
    );
  }
}

class _CameraChrome extends StatelessWidget {
  const _CameraChrome({
    required this.controller,
    required this.state,
    required this.onClose,
  });

  final CameraWidgetController controller;
  final CameraState state;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                const Spacer(),
                StreamBuilder<SensorConfig>(
                  stream: state.sensorConfig$,
                  builder: (context, cfgSnap) {
                    if (!cfgSnap.hasData) {
                      return TextButton(
                        onPressed: null,
                        child: Text(controller.changingAspectRatio ? '…' : '比例'),
                      );
                    }
                    final cfg = cfgSnap.requireData;
                    return StreamBuilder<CameraAspectRatios>(
                      stream: cfg.aspectRatio$,
                      initialData: cfg.aspectRatio,
                      builder: (context, ratioSnap) {
                        final ratio = ratioSnap.data ?? CameraAspectRatios.ratio_4_3;
                        final busy = controller.changingAspectRatio;
                        return TextButton(
                          onPressed: busy ? null : () => controller.cycleAspectRatio(),
                          child: Text(
                            busy ? '…' : aspectRatioLabel(ratio),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeBar(controller: controller, state: state),
                  const SizedBox(height: 20),
                  _ShutterButton(
                    state: state,
                    busy: controller.capturingPhoto,
                    onPressed: () => controller.shutter(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.controller, required this.state});

  final CameraWidgetController controller;
  final CameraState state;

  @override
  Widget build(BuildContext context) {
    final recording = state is VideoRecordingCameraState;
    final isVideoMode = state.when(
      onPhotoMode: (_) => false,
      onVideoMode: (_) => true,
      onVideoRecordingMode: (_) => true,
      onPreparingCamera: (_) => false,
      onPreviewMode: (_) => false,
      onAnalysisOnlyMode: (_) => false,
    );
    const chipOn = Color(0xFF37474F);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('拍照'),
          labelStyle: const TextStyle(color: Colors.white),
          selectedColor: chipOn,
          backgroundColor: Colors.black26,
          selected: !isVideoMode && !recording,
          onSelected: recording
              ? null
              : (_) {
                  if (!isVideoMode) return;
                  controller.setCaptureMode(CaptureMode.photo);
                },
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('录像'),
          labelStyle: const TextStyle(color: Colors.white),
          selectedColor: chipOn,
          backgroundColor: Colors.black26,
          selected: isVideoMode,
          onSelected: (_) {
            if (recording) return;
            if (isVideoMode) return;
            controller.setCaptureMode(CaptureMode.video);
          },
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.state, required this.busy, required this.onPressed});

  final CameraState state;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return state.when(
      onPhotoMode: (_) => _circleShutter(loading: busy, onTap: busy ? null : onPressed),
      onVideoMode: (_) => _circleShutter(loading: false, filled: true, onTap: onPressed),
      onVideoRecordingMode: (_) => _stopShutter(onTap: onPressed),
      onPreparingCamera: (_) => const SizedBox(width: 72, height: 72),
      onPreviewMode: (_) => const SizedBox.shrink(),
      onAnalysisOnlyMode: (_) => const SizedBox.shrink(),
    );
  }

  static Widget _circleShutter({required bool loading, bool filled = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 72,
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                )
              : Center(
                  child: Container(
                    width: filled ? 56 : 64,
                    height: filled ? 56 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.redAccent : Colors.transparent,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  static Widget _stopShutter({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
