part of '../camera_widget.dart';

/// 处理点击对焦 / 双指变焦的透明手势层。
class _GestureLayer extends StatefulWidget {
  const _GestureLayer({
    required this.controller,
    required this.enableTap,
    required this.enableScale,
    required this.previewSize,
    this.onTap,
  });

  final CameraxController controller;
  final bool enableTap;
  final bool enableScale;
  final Size previewSize;
  final void Function(Offset localPosition, Offset normalized)? onTap;

  @override
  State<_GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<_GestureLayer> {
  double _baselineZoom = 1;

  /// 点击时转成归一化坐标并提交对焦/测光点。
  void _handleTapUp(TapUpDetails details) {
    final size = widget.previewSize;
    if (size.width <= 0 || size.height <= 0) return;
    final pos = details.localPosition;
    final normalized = Offset(
      (pos.dx / size.width).clamp(0.0, 1.0),
      (pos.dy / size.height).clamp(0.0, 1.0),
    );
    widget.controller.setFocusAndMeteringPoint(normalized);
    widget.onTap?.call(pos, normalized);
  }

  /// 记录双指缩放起始倍率。
  void _handleScaleStart(ScaleStartDetails details) {
    _baselineZoom = widget.controller.zoomLevel;
  }

  /// 仅在双指场景下按比例变焦。
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    widget.controller.setZoomLevel(_baselineZoom * details.scale);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: widget.enableTap ? _handleTapUp : null,
      onScaleStart: widget.enableScale ? _handleScaleStart : null,
      onScaleUpdate: widget.enableScale ? _handleScaleUpdate : null,
    );
  }
}
