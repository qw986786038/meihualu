import 'dart:async' show unawaited;

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';

/// 与 [Colors.black] `alpha: 0.42` 一致；变焦条与镜头按钮共用。
const Color _kCameraOverlayBarFill = Colors.black26;

const EdgeInsets _kCameraZoomCapsulePadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 6,
);

/// 变焦条与镜头切换按钮统一高度（含变焦条上下内边距 + Slider 触控区）。
const double _kCameraOverlayControlBarHeight = 45;

/// 主页：打开相机（仍由 [onPressed] 负责路由，同时持有 [controller] 用于展示 Tooltip）。
class HomeOpenCameraButton extends StatelessWidget {
  const HomeOpenCameraButton({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  final CameraxController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        return Tooltip(
          message: '可用相机: ${controller.cameras.length}',
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.photo_camera),
            label: const Text('打开相机'),
          ),
        );
      },
    );
  }
}

/// 主页：在未初始化时触发 [CameraxController.initialize]。
class HomeEarlyInitializeButton extends StatelessWidget {
  const HomeEarlyInitializeButton({super.key, required this.controller});

  final CameraxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) => OutlinedButton.icon(
        onPressed: controller.status == CameraxStatus.uninitialized
            ? controller.initialize
            : null,
        icon: const Icon(Icons.refresh),
        label: const Text('提前初始化'),
      ),
    );
  }
}

/// 预览比例菜单；拍照模式下可选，选中值由外层维护（写给 [CameraWidget.previewRatio]）。
class CameraPreviewRatioMenuButton extends StatelessWidget {
  const CameraPreviewRatioMenuButton({
    super.key,
    required this.controller,
    required this.photoPreviewRatio,
    required this.onPhotoPreviewRatioChanged,
  });

  final CameraxController controller;
  final CameraPreviewRatio photoPreviewRatio;
  final ValueChanged<CameraPreviewRatio> onPhotoPreviewRatioChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) => PopupMenuButton<CameraPreviewRatio>(
        tooltip: '预览比例',
        enabled: controller.operationMode == CameraxOperationMode.photo,
        initialValue: photoPreviewRatio,
        onSelected: onPhotoPreviewRatioChanged,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: CameraPreviewRatio.fullscreen,
            child: Text('全屏'),
          ),
          PopupMenuItem(value: CameraPreviewRatio.ratio1x1, child: Text('1:1')),
          PopupMenuItem(value: CameraPreviewRatio.ratio3x4, child: Text('3:4')),
          PopupMenuItem(
            value: CameraPreviewRatio.ratio16x9,
            child: Text('16:9'),
          ),
        ],
        icon: const Icon(Icons.aspect_ratio),
      ),
    );
  }
}

Future<void> _cycleFlashMode(CameraxController c) async {
  const order = [
    FlashMode.auto,
    FlashMode.always,
    FlashMode.torch,
    FlashMode.off,
  ];
  final next = order[(order.indexOf(c.flashMode) + 1) % order.length];
  await c.setFlashMode(next);
}

IconData _flashModeIcon(FlashMode mode) {
  switch (mode) {
    case FlashMode.auto:
      return Icons.flash_auto;
    case FlashMode.always:
      return Icons.flash_on;
    case FlashMode.torch:
      return Icons.flashlight_on;
    case FlashMode.off:
      return Icons.flash_off;
  }
}

/// 依次切换闪光灯 / 手电筒模式。
class CameraFlashModeButton extends StatelessWidget {
  const CameraFlashModeButton({super.key, required this.controller});

  final CameraxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) => IconButton(
        icon: Icon(_flashModeIcon(controller.flashMode)),
        onPressed: controller.isReady
            ? () => _cycleFlashMode(controller)
            : null,
      ),
    );
  }
}

/// 拍照 / 录像模式切换（录像中禁用）。
class CameraPhotoVideoModeButton extends StatelessWidget {
  const CameraPhotoVideoModeButton({super.key, required this.controller});

  final CameraxController controller;

  static final _style = SegmentedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    side: BorderSide.none,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white70,
    selectedBackgroundColor: Colors.transparent,
    selectedForegroundColor: Colors.red,
    textStyle: _segmentTextStyle,
  );

  static const TextStyle _segmentTextStyle = TextStyle(
    fontSize: 18,
    shadows: [
      Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
      Shadow(color: Colors.black26, offset: Offset(-1, -1), blurRadius: 2),
    ],
  );

  static const _segments = <ButtonSegment<CameraxOperationMode>>[
    ButtonSegment<CameraxOperationMode>(
      value: CameraxOperationMode.photo,
      label: Text('拍照'),
    ),
    ButtonSegment<CameraxOperationMode>(
      value: CameraxOperationMode.video,
      label: Text('录像'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) => SegmentedButton<CameraxOperationMode>(
        style: _style,
        showSelectedIcon: false,
        segments: _segments,
        selected: {controller.operationMode},
        onSelectionChanged: controller.isRecording
            ? null
            : (selection) => controller.setOperationMode(selection.first),
      ),
    );
  }
}

String _formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// 录像计时提示（红点 + 时间），默认放在 AppBar 下方。
class CameraRecordingTimerBadge extends StatelessWidget {
  const CameraRecordingTimerBadge({super.key, required this.controller});

  final CameraxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        if (!controller.isRecording) {
          return const SizedBox(height: 12);
        }
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRecordingDuration(controller.recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatZoomLabel(double z) =>
    z >= 10 ? z.toStringAsFixed(0) : z.toStringAsFixed(1);

/// 横向胶囊形变焦条，依赖 [CameraxController] 的变焦区间与 [setZoomLevel]。
class CameraZoomCapsuleBar extends StatelessWidget {
  const CameraZoomCapsuleBar({super.key, required this.controller});

  final CameraxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        if (!controller.isReady) return const SizedBox.shrink();
        final minZ = controller.minZoomLevel;
        final maxZ = controller.maxZoomLevel;
        if (maxZ <= minZ) return const SizedBox.shrink();

        final value = controller.zoomLevel.clamp(minZ, maxZ);
        final labelStyle = TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
          ],
        );

        return Material(
          color: Colors.transparent,
          child: SizedBox(
            height: _kCameraOverlayControlBarHeight,
            child: Container(
              padding: _kCameraZoomCapsulePadding,
              decoration: BoxDecoration(
                color: _kCameraOverlayBarFill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: Colors.white.withValues(alpha: 0.95),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.12),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('${_formatZoomLabel(minZ)}×', style: labelStyle),
                    Expanded(
                      child: Slider(
                        value: value,
                        min: minZ,
                        max: maxZ,
                        label: '${_formatZoomLabel(value)}×',
                        onChanged: (v) => unawaited(controller.setZoomLevel(v)),
                      ),
                    ),
                    Text('${_formatZoomLabel(maxZ)}×', style: labelStyle),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 前后摄（或多摄）切换。
class CameraLensSwitchButton extends StatelessWidget {
  const CameraLensSwitchButton({super.key, required this.controller});

  final CameraxController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final enabled =
            controller.cameras.length > 1 && !controller.isRecording;
        return SizedBox(
          width: _kCameraOverlayControlBarHeight,
          height: _kCameraOverlayControlBarHeight,
          child: Material(
            color: _kCameraOverlayBarFill,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? controller.switchLensDirection : null,
              child: Center(
                child: Icon(
                  Icons.cameraswitch,
                  size: 28,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.38),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 快门：拍照模式下调用 [CameraxController.takePicture]；录像模式下开始/停止录制。
class CameraShutterButton extends StatelessWidget {
  const CameraShutterButton({
    super.key,
    required this.controller,
    this.onStartVideoRecording,
    this.onStopVideoRecording,
  });

  final CameraxController controller;
  final Future<void> Function()? onStartVideoRecording;
  final Future<void> Function()? onStopVideoRecording;

  Future<void> _onTap(CameraxController c) async {
    if (c.operationMode == CameraxOperationMode.video) {
      if (c.isRecording) {
        if (onStopVideoRecording != null) {
          await onStopVideoRecording!();
        } else {
          await c.stopVideoRecording();
        }
      } else {
        if (onStartVideoRecording != null) {
          await onStartVideoRecording!();
        } else {
          await c.startVideoRecording();
        }
      }
    } else if (!c.isTakingPicture) {
      await c.takePicture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final c = controller;
        final isVideoMode = c.operationMode == CameraxOperationMode.video;

        return GestureDetector(
          onTap: isVideoMode
              ? () => _onTap(c)
              : (c.isTakingPicture ? null : () => _onTap(c)),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: isVideoMode
                    ? (c.isRecording ? Colors.redAccent : Colors.white)
                    : Colors.white,
                width: 4,
              ),
            ),
            child: isVideoMode
                ? Icon(
                    c.isRecording
                        ? Icons.stop_circle_outlined
                        : Icons.fiber_manual_record,
                    color: c.isRecording ? Colors.redAccent : Colors.white,
                    size: 34,
                  )
                : c.isTakingPicture
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
