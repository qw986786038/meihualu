import 'dart:async' show Timer, unawaited;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camerax_controller.dart';
part 'camera_widget/default_error.dart';
part 'camera_widget/focus_exposure_bar.dart';
part 'camera_widget/focus_indicator.dart';
part 'camera_widget/gesture_layer.dart';
part 'camera_widget/preview_content.dart';

/// 预览画幅比例。
enum CameraPreviewRatio {
  /// 全屏显示（由 [CameraWidget.fit] 决定 cover / contain）。
  fullscreen,

  /// 正方形预览。
  ratio1x1,

  /// 3:4 预览（竖屏时为 3:4，横屏时为 4:3）。
  ratio3x4,

  /// 16:9 预览（竖屏时为 9:16，横屏时为 16:9）。
  ratio16x9,
}

/// 相机预览组件。
///
/// 只负责绘制预览画面与处理生命周期，不内置业务按钮。
///
/// 覆盖层建议：
/// - 使用 [overlay] / [overlayBuilder]：只覆盖预览区域（会跟随预览比例变化）。
/// - 使用 [fullOverlayBuilder]：覆盖整个容器（操作 UI 固定不动，按 [previewRect] 自定位）。
///
/// 预览比例切换由 [previewRatio] 控制，且内置平滑动画（时长/曲线可配）。
///
/// ```dart
/// CameraWidget(
///   controller: controller,
///   overlayBuilder: (context, previewSize) {
///     return Stack(
///       children: [
///         Positioned(
///           bottom: 24,
///           left: 0, right: 0,
///           child: ShutterButton(...),
///         ),
///       ],
///     );
///   },
/// )
/// ```
class CameraWidget extends StatefulWidget {
  const CameraWidget({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
    this.overlay,
    this.overlayBuilder,
    this.fullOverlayBuilder,
    this.placeholderBuilder,
    this.errorBuilder,
    this.autoInitialize = true,
    this.handleLifecycle = true,
    this.backgroundColor = Colors.black,
    this.tapToFocus = true,
    this.pinchToZoom = true,
    this.onFocusTap,
    this.showFocusIndicator = true,
    this.focusIndicatorDuration = const Duration(milliseconds: 1500),
    this.focusIndicatorSize = 64,
    this.focusIndicatorColor = Colors.yellow,
    this.focusIndicatorStrokeWidth = 2,
    this.previewRatioAnimationDuration = const Duration(milliseconds: 240),
    this.previewRatioAnimationCurve = Curves.easeInOutCubic,
    this.previewRatio = CameraPreviewRatio.fullscreen,
    this.previewLetterboxTargetTop,
    this.previewLetterboxTargetLeft,
    this.previewLetterboxShift = Offset.zero,
  }) : assert(
         overlay == null || overlayBuilder == null,
         'overlay 与 overlayBuilder 二选一即可',
       );

  /// 相机控制器，由调用方负责创建与释放。
  final CameraxController controller;

  /// 预览的填充方式。
  ///
  /// - [BoxFit.cover]（默认）：等比放大铺满父容器，多余部分裁掉，**没有黑边**，
  ///   此时 `previewSize` 等于父容器尺寸。
  /// - [BoxFit.contain]：等比缩小完整显示，**可能出现黑边**，
  ///   `previewSize` 是去掉黑边后的实际可视区域。
  final BoxFit fit;

  /// 简单的覆盖层。会被精确放置在真实预览矩形之上，
  /// 其布局约束 = 预览区域大小。
  ///
  /// 与 [overlayBuilder] 二选一。
  final Widget? overlay;

  /// 带 [Size] 信息的覆盖层构建器。
  ///
  /// 回调中拿到的 `previewSize` 即真实预览矩形大小（不含黑边）。
  /// 与 [overlay] 二选一。
  final Widget Function(BuildContext context, Size previewSize)? overlayBuilder;

  /// 全屏覆盖层构建器。
  ///
  /// 与 [overlay]/[overlayBuilder] 不同，这一层始终铺满父容器。
  /// 可用于放置不随预览框变化的操作 UI，或绘制预览框外蒙版。
  ///
  /// - [previewRect]：预览区域在父容器内的矩形。
  /// - [containerSize]：父容器尺寸。
  final Widget Function(
    BuildContext context,
    Rect previewRect,
    Size containerSize,
  )?
  fullOverlayBuilder;

  /// 自定义未就绪 / 加载中的占位 UI。
  final WidgetBuilder? placeholderBuilder;

  /// 自定义错误 UI。回调中提供错误信息以及重试动作。
  final Widget Function(
    BuildContext context,
    String message,
    VoidCallback retry,
  )?
  errorBuilder;

  /// 挂载时若 controller 处于 [CameraxStatus.uninitialized]，是否自动初始化。
  final bool autoInitialize;

  /// 是否监听 App 生命周期，自动暂停 / 恢复预览。
  final bool handleLifecycle;

  /// 预览框背景色（黑边区域颜色）。
  final Color backgroundColor;

  /// 是否启用「点击对焦 + 测光」。
  final bool tapToFocus;

  /// 是否启用双指缩放变焦。
  final bool pinchToZoom;

  /// 点击对焦时回调，可用于在 [overlay] 中绘制对焦动画。
  ///
  /// - `localPosition`：点击位置在预览矩形内的局部坐标。
  /// - `normalized`：归一化后传给底层的对焦点（0..1）。
  final void Function(Offset localPosition, Offset normalized)? onFocusTap;

  /// 是否显示内置点击对焦圈。
  ///
  /// 为 true 时，对焦圈显示期间在其右侧会附带一条可上下拖动的曝光补偿竖条
  ///（调整 [CameraxController.exposureOffset]）。
  final bool showFocusIndicator;

  /// 内置点击对焦圈显示时长。
  final Duration focusIndicatorDuration;

  /// 内置点击对焦圈尺寸。
  final double focusIndicatorSize;

  /// 内置点击对焦圈颜色。
  final Color focusIndicatorColor;

  /// 内置点击对焦圈边框宽度。
  final double focusIndicatorStrokeWidth;

  /// 预览比例切换动画时长。
  final Duration previewRatioAnimationDuration;

  /// 预览比例切换动画曲线。
  final Curve previewRatioAnimationCurve;

  /// 预览画幅比例。
  ///
  /// 默认 [CameraPreviewRatio.fullscreen]。
  final CameraPreviewRatio previewRatio;

  /// 存在上下黑边时，期望的**上侧黑边高度**（逻辑像素）。
  ///
  /// 与居中结果相比，会将预览区垂直平移，使 `previewRect.top` 尽量接近该值。
  /// 先钳制到 `[0, 容器高 − 预览高]`：例如总竖直黑边只有 100 时写 120，只会按 100 生效，
  /// 再与 [previewLetterboxShift] 叠加，最后仍钳制在可滑动范围内。
  /// 为 null 则不在此维度上对齐目标，仅由 [previewLetterboxShift] 平移。
  final double? previewLetterboxTargetTop;

  /// 存在左右黑边时，期望的**左侧黑边宽度**（逻辑像素）。
  ///
  /// 与 [previewLetterboxTargetTop] 相同，会先钳制到 `[0, 容器宽 − 预览宽]`。
  final double? previewLetterboxTargetLeft;

  /// 在居中（及可选的目标黑边对齐）之后，再叠加的平移量。
  ///
  /// 正 [Offset.dy] 表示整体下移，上黑边变宽、下黑边变窄。
  final Offset previewLetterboxShift;

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  Offset? _focusIndicator;
  Timer? _focusIndicatorHideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.handleLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
    if (widget.autoInitialize &&
        widget.controller.status == CameraxStatus.uninitialized) {
      // 不得在 initState 同步调用 [CameraxController.initialize]：其内部会立即
      // notifyListeners，而父级路由上的 ListenableBuilder 可能仍在 build，
      // 触发 “setState/markNeedsBuild called during build”。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = widget.controller;
        if (c.status != CameraxStatus.uninitialized) return;
        c.initialize();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.handleLifecycle != oldWidget.handleLifecycle) {
      if (widget.handleLifecycle) {
        WidgetsBinding.instance.addObserver(this);
      } else {
        WidgetsBinding.instance.removeObserver(this);
      }
    }
  }

  @override
  void dispose() {
    _focusIndicatorHideTimer?.cancel();
    if (widget.handleLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = widget.controller.cameraController;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      widget.controller.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.resumePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    switch (controller.status) {
      case CameraxStatus.uninitialized:
      case CameraxStatus.initializing:
        return widget.placeholderBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator(color: Colors.white));
      case CameraxStatus.error:
        final msg = controller.errorMessage ?? '相机错误';
        return widget.errorBuilder?.call(context, msg, controller.initialize) ??
            _DefaultError(message: msg, onRetry: controller.initialize);
      case CameraxStatus.disposed:
        return const SizedBox.shrink();
      case CameraxStatus.ready:
        return _buildPreview(context);
    }
  }

  Widget _buildPreview(BuildContext context) {
    final cam = widget.controller.cameraController;
    if (cam == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxW = constraints.maxWidth;
        final boxH = constraints.maxHeight;
        final isPortrait = boxH >= boxW;
        // CameraPreview 实际渲染出的可视纵横比：竖屏时为 1 / aspectRatio。
        final cameraAspect = isPortrait
            ? 1 / cam.value.aspectRatio
            : cam.value.aspectRatio;

        final isFullscreen =
            widget.previewRatio == CameraPreviewRatio.fullscreen;
        final targetAspect = isFullscreen
            ? cameraAspect
            : _fixedPreviewAspect(widget.previewRatio, isPortrait);

        final basePreviewRect = isFullscreen
            ? _computePreviewRect(
                boxW: boxW,
                boxH: boxH,
                previewAspect: targetAspect,
                fit: widget.fit,
              )
            : _computePreviewRect(
                boxW: boxW,
                boxH: boxH,
                previewAspect: targetAspect,
                fit: BoxFit.contain,
              );
        final previewRect = _applyLetterboxPositioning(
          base: basePreviewRect,
          boxW: boxW,
          boxH: boxH,
          targetTop: widget.previewLetterboxTargetTop,
          targetLeft: widget.previewLetterboxTargetLeft,
          shift: widget.previewLetterboxShift,
        );
        final aspectRatio = previewRect.width / previewRect.height;
        final containerSize = Size(boxW, boxH);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.controller
            ..updateCaptureAspectRatio(aspectRatio)
            ..updatePreviewLetterbox(
              containerSize: containerSize,
              previewRect: previewRect,
            );
        });

        final previewFit = isFullscreen ? widget.fit : BoxFit.cover;
        final focusExposureBarHeight = (widget.focusIndicatorSize * 2.4).clamp(
          88.0,
          144.0,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPositioned.fromRect(
              key: const ValueKey('preview-positioned'),
              rect: previewRect,
              duration: widget.previewRatioAnimationDuration,
              curve: widget.previewRatioAnimationCurve,
              child: ClipRect(
                child: RepaintBoundary(
                  child: _PreviewContent(
                    controller: cam,
                    previewAspect: cameraAspect,
                    fit: previewFit,
                  ),
                ),
              ),
            ),
            if (widget.tapToFocus || widget.pinchToZoom)
              AnimatedPositioned.fromRect(
                key: const ValueKey('gesture-positioned'),
                rect: previewRect,
                duration: widget.previewRatioAnimationDuration,
                curve: widget.previewRatioAnimationCurve,
                child: _GestureLayer(
                  controller: widget.controller,
                  enableTap: widget.tapToFocus,
                  enableScale: widget.pinchToZoom,
                  previewSize: previewRect.size,
                  onTap: (local, normalized) {
                    _handleFocusTap(local, normalized);
                    widget.onFocusTap?.call(local, normalized);
                  },
                ),
              ),
            if (widget.showFocusIndicator && _focusIndicator != null) ...[
              AnimatedPositioned(
                key: const ValueKey('focus-indicator-positioned'),
                left:
                    previewRect.left +
                    _focusIndicator!.dx -
                    widget.focusIndicatorSize / 2,
                top:
                    previewRect.top +
                    _focusIndicator!.dy -
                    widget.focusIndicatorSize / 2,
                duration: widget.previewRatioAnimationDuration,
                curve: widget.previewRatioAnimationCurve,
                child: IgnorePointer(
                  child: _AnimatedFocusIndicator(
                    size: widget.focusIndicatorSize,
                    color: widget.focusIndicatorColor,
                    strokeWidth: widget.focusIndicatorStrokeWidth,
                  ),
                ),
              ),
              AnimatedPositioned(
                key: const ValueKey('focus-exposure-bar-positioned'),
                duration: widget.previewRatioAnimationDuration,
                curve: widget.previewRatioAnimationCurve,
                left:
                    previewRect.left +
                    _focusIndicator!.dx +
                    widget.focusIndicatorSize / 2 +
                    8,
                top:
                    previewRect.top +
                    _focusIndicator!.dy -
                    focusExposureBarHeight / 2,
                width: 28,
                height: focusExposureBarHeight,
                child: _FocusExposureBar(
                  controller: widget.controller,
                  height: focusExposureBarHeight,
                  accentColor: widget.focusIndicatorColor,
                  lineStrokeWidth: widget.focusIndicatorStrokeWidth,
                  onInteractionStart: _suspendFocusIndicatorAutoHide,
                  onInteractionEnd: _onFocusExposureBarInteractionEnd,
                ),
              ),
            ],
            if (widget.overlay != null || widget.overlayBuilder != null)
              AnimatedPositioned.fromRect(
                key: const ValueKey('overlay-positioned'),
                rect: previewRect,
                duration: widget.previewRatioAnimationDuration,
                curve: widget.previewRatioAnimationCurve,
                child:
                    widget.overlay ??
                    Builder(
                      builder: (ctx) =>
                          widget.overlayBuilder!(ctx, previewRect.size),
                    ),
              ),
            if (widget.fullOverlayBuilder != null)
              Positioned.fill(
                child: TweenAnimationBuilder<RelativeRect>(
                  tween: RelativeRectTween(
                    end: RelativeRect.fromRect(
                      previewRect,
                      Offset.zero & Size(boxW, boxH),
                    ),
                  ),
                  duration: widget.previewRatioAnimationDuration,
                  curve: widget.previewRatioAnimationCurve,
                  builder: (ctx, animatedRect, _) => widget.fullOverlayBuilder!(
                    ctx,
                    animatedRect.toRect(Offset.zero & Size(boxW, boxH)),
                    Size(boxW, boxH),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 在居中矩形 [base] 之上，按目标黑边 / 平移量滑动预览区，并钳制在容器内。
  static Rect _applyLetterboxPositioning({
    required Rect base,
    required double boxW,
    required double boxH,
    required double? targetTop,
    required double? targetLeft,
    required Offset shift,
  }) {
    final hasLetterboxH = base.width < boxW - 0.5;
    final hasLetterboxV = base.height < boxH - 0.5;
    if (!hasLetterboxH && !hasLetterboxV) {
      return base;
    }

    final minL = 0.0;
    final maxL = boxW - base.width;
    final minT = 0.0;
    final maxT = boxH - base.height;

    var dx = shift.dx;
    var dy = shift.dy;
    if (hasLetterboxH && targetLeft != null) {
      // 左/上黑边物理上限即预览区可平移范围；超出则只生效到边界（如写 120 总只有 100 则按 100）。
      final clampedLeftBlack = targetLeft.clamp(minL, maxL);
      dx += clampedLeftBlack - base.left;
    }
    if (hasLetterboxV && targetTop != null) {
      final clampedTopBlack = targetTop.clamp(minT, maxT);
      dy += clampedTopBlack - base.top;
    }

    final newLeft = (base.left + dx).clamp(minL, maxL);
    final newTop = (base.top + dy).clamp(minT, maxT);
    return Rect.fromLTWH(newLeft, newTop, base.width, base.height);
  }

  /// 计算预览画面在父容器中的真实可视矩形（不含黑边）。
  static Rect _computePreviewRect({
    required double boxW,
    required double boxH,
    required double previewAspect,
    required BoxFit fit,
  }) {
    if (fit == BoxFit.cover) {
      // 铺满整个父容器，没有黑边。
      return Rect.fromLTWH(0, 0, boxW, boxH);
    }
    // contain：等比缩放后居中，剩余即黑边。
    final boxAspect = boxW / boxH;
    double w;
    double h;
    if (previewAspect > boxAspect) {
      w = boxW;
      h = boxW / previewAspect;
    } else {
      h = boxH;
      w = boxH * previewAspect;
    }
    final left = (boxW - w) / 2;
    final top = (boxH - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  static double _fixedPreviewAspect(CameraPreviewRatio ratio, bool isPortrait) {
    switch (ratio) {
      case CameraPreviewRatio.fullscreen:
        return 1;
      case CameraPreviewRatio.ratio1x1:
        return 1;
      case CameraPreviewRatio.ratio3x4:
        return isPortrait ? 3 / 4 : 4 / 3;
      case CameraPreviewRatio.ratio16x9:
        return isPortrait ? 9 / 16 : 16 / 9;
    }
  }

  void _handleFocusTap(Offset localPosition, Offset normalized) {
    if (!widget.showFocusIndicator) return;
    _focusIndicatorHideTimer?.cancel();
    _focusIndicatorHideTimer = null;
    setState(() => _focusIndicator = localPosition);
    _scheduleFocusIndicatorHide();
  }

  void _scheduleFocusIndicatorHide() {
    _focusIndicatorHideTimer?.cancel();
    if (!widget.showFocusIndicator || _focusIndicator == null) return;
    _focusIndicatorHideTimer = Timer(widget.focusIndicatorDuration, () {
      if (!mounted) return;
      setState(() {
        _focusIndicator = null;
        _focusIndicatorHideTimer = null;
      });
    });
  }

  /// 曝光条拖动期间不自动收对焦框。
  void _suspendFocusIndicatorAutoHide() {
    _focusIndicatorHideTimer?.cancel();
    _focusIndicatorHideTimer = null;
  }

  void _resumeFocusIndicatorAutoHide() {
    if (!widget.showFocusIndicator || _focusIndicator == null) return;
    _scheduleFocusIndicatorHide();
  }

  void _onFocusExposureBarInteractionEnd() {
    unawaited(widget.controller.finalizeManualExposureLock());
    _resumeFocusIndicatorAutoHide();
  }
}
