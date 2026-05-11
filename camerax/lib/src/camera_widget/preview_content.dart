part of '../camera_widget.dart';

/// 实际承载 [CameraPreview] 的部分。
///
/// 不能在 [CameraPreview] 外再包错误的 `AspectRatio(cam.value.aspectRatio)`：
/// `CameraPreview` 内部已根据设备方向旋转，再用横向纵横比强制约束会把画面压扁。
class _PreviewContent extends StatelessWidget {
  const _PreviewContent({
    required this.controller,
    required this.previewAspect,
    required this.fit,
  });

  final CameraController controller;
  final double previewAspect;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // 先用相机原始纵横比构建预览，再按 fit 决定是否裁切。
    final preview = AspectRatio(
      aspectRatio: previewAspect,
      child: CameraPreview(controller),
    );

    if (fit == BoxFit.contain) {
      return Center(child: preview);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxAspect = constraints.maxWidth / constraints.maxHeight;
        var scale = boxAspect / previewAspect;
        if (scale < 1) scale = 1 / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(child: preview),
          ),
        );
      },
    );
  }
}
