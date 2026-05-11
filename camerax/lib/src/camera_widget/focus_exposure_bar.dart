part of '../camera_widget.dart';

/// 对焦框右侧的曝光补偿竖条：沿高度拖动可改变 [CameraxController.exposureOffset]。
class _FocusExposureBar extends StatelessWidget {
  const _FocusExposureBar({
    required this.controller,
    required this.height,
    required this.accentColor,
    required this.lineStrokeWidth,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  static const double _kWidth = 28;
  static const double _kSunSize = 24;
  /// 控件整体上下留白。
  static const double _kLinePadding = 6;
  /// 竖线比太阳可走区域再缩短（两端各缩一环）。
  static const double _kLineLengthInset = 12;

  final CameraxController controller;
  final double height;
  /// 与对焦框 [CameraWidget.focusIndicatorColor] 一致。
  final Color accentColor;
  /// 竖线线宽，与对焦框描边 [CameraWidget.focusIndicatorStrokeWidth] 对齐。
  final double lineStrokeWidth;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  void _applyLocalY(double localY) {
    final minEv = controller.minExposureOffset;
    final maxEv = controller.maxExposureOffset;
    final span = maxEv - minEv;
    if (span <= 1e-6 || height <= 0) return;
    // 与太阳图标可走区域一致：顶 = 最大 EV，底 = 最小 EV
    final innerTop = _kLinePadding + _kSunSize / 2;
    final innerBottom = height - _kLinePadding - _kSunSize / 2;
    final innerH = innerBottom - innerTop;
    if (innerH <= 0) return;
    final t = 1.0 -
        ((localY - innerTop) / innerH).clamp(0.0, 1.0);
    final ev = minEv + t * span;
    unawaited(controller.setExposureOffset(ev));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final minEv = controller.minExposureOffset;
        final maxEv = controller.maxExposureOffset;
        final span = maxEv - minEv;

        return SizedBox(
          width: _kWidth,
          height: height,
          child: span <= 1e-6
              ? const SizedBox.shrink()
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    onInteractionStart?.call();
                    _applyLocalY(d.localPosition.dy);
                  },
                  onTapUp: (_) => onInteractionEnd?.call(),
                  onTapCancel: () => onInteractionEnd?.call(),
                  onVerticalDragStart: (d) {
                    onInteractionStart?.call();
                    _applyLocalY(d.localPosition.dy);
                  },
                  onVerticalDragUpdate: (d) =>
                      _applyLocalY(d.localPosition.dy),
                  onVerticalDragEnd: (_) => onInteractionEnd?.call(),
                  onVerticalDragCancel: () => onInteractionEnd?.call(),
                  child: _ExposureLineWithSunThumb(
                    width: _kWidth,
                    height: height,
                    accentColor: accentColor,
                    lineStrokeWidth: lineStrokeWidth,
                    progress: ((controller.exposureOffset.clamp(minEv, maxEv) -
                                minEv) /
                            span)
                        .clamp(0.0, 1.0),
                  ),
                ),
        );
      },
    );
  }
}

/// 竖线轨道 + 小太阳滑块（位置表示当前 EV）。
class _ExposureLineWithSunThumb extends StatelessWidget {
  const _ExposureLineWithSunThumb({
    required this.width,
    required this.height,
    required this.accentColor,
    required this.lineStrokeWidth,
    required this.progress,
  });

  final double width;
  final double height;
  final Color accentColor;
  final double lineStrokeWidth;
  /// 0 = 最小 EV（下方），1 = 最大 EV（上方）。
  final double progress;

  static const double _sun = _FocusExposureBar._kSunSize;
  static const double _pad = _FocusExposureBar._kLinePadding;

  @override
  Widget build(BuildContext context) {
    final trackTop = _pad + _sun / 2;
    final trackBottom = height - _pad - _sun / 2;
    final span = (trackBottom - trackTop).clamp(1.0, double.infinity);
    var centerY = trackBottom - progress * span;
    centerY = centerY.clamp(trackTop, trackBottom);

    var lineTop = trackTop + _FocusExposureBar._kLineLengthInset;
    var lineBottom = trackBottom - _FocusExposureBar._kLineLengthInset;
    if (lineTop >= lineBottom) {
      lineTop = trackTop + 4;
      lineBottom = trackBottom - 4;
      if (lineTop >= lineBottom) {
        lineTop = trackTop;
        lineBottom = trackBottom;
      }
    }

    // 与 24px 太阳视觉中心一致；略大于半径使线条与图标不相交。
    final gapR = _sun / 2 + 2;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _ExposureVerticalLineWithSunGapPainter(
              color: accentColor,
              strokeWidth: lineStrokeWidth,
              lineTop: lineTop.clamp(0.0, height),
              lineBottom: lineBottom.clamp(0.0, height),
              sunCenterY: centerY,
              sunClearRadius: gapR,
            ),
          ),
          Positioned(
            left: (width - _sun) / 2,
            width: _sun,
            top: centerY - _sun / 2,
            height: _sun,
            child: IgnorePointer(
              child: Icon(
                Icons.wb_sunny_rounded,
                size: _sun,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 竖线在 [sunCenterY] 处留出圆形间隙，避免与太阳图标重叠。
class _ExposureVerticalLineWithSunGapPainter extends CustomPainter {
  _ExposureVerticalLineWithSunGapPainter({
    required this.color,
    required this.strokeWidth,
    required this.lineTop,
    required this.lineBottom,
    required this.sunCenterY,
    required this.sunClearRadius,
  });

  final Color color;
  final double strokeWidth;
  final double lineTop;
  final double lineBottom;
  final double sunCenterY;
  final double sunClearRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final g0 = sunCenterY - sunClearRadius;
    final g1 = sunCenterY + sunClearRadius;

    if (lineTop < g0) {
      canvas.drawLine(Offset(x, lineTop), Offset(x, g0), p);
    }
    if (g1 < lineBottom) {
      canvas.drawLine(Offset(x, g1), Offset(x, lineBottom), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ExposureVerticalLineWithSunGapPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.lineTop != lineTop ||
        oldDelegate.lineBottom != lineBottom ||
        oldDelegate.sunCenterY != sunCenterY ||
        oldDelegate.sunClearRadius != sunClearRadius;
  }
}
