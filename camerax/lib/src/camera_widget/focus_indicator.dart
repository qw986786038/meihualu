part of '../camera_widget.dart';

/// 对焦提示框（静态角标样式）。
class _FocusIndicator extends StatelessWidget {
  const _FocusIndicator({
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final cornerLen = (size * 0.22).clamp(8.0, 22.0).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FocusIndicatorPainter(
          color: color,
          strokeWidth: strokeWidth,
          cornerLength: cornerLen,
        ),
      ),
    );
  }
}

class _AnimatedFocusIndicator extends StatefulWidget {
  const _AnimatedFocusIndicator({
    required this.size,
    required this.color,
    required this.strokeWidth,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  State<_AnimatedFocusIndicator> createState() => _AnimatedFocusIndicatorState();
}

/// 对焦提示框呼吸动画（透明度 + 轻微缩放）。
class _AnimatedFocusIndicatorState extends State<_AnimatedFocusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    final opacity = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: scale,
        child: _FocusIndicator(
          size: widget.size,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

class _FocusIndicatorPainter extends CustomPainter {
  const _FocusIndicatorPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  final Color color;
  final double strokeWidth;
  final double cornerLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;
    final l = cornerLength;
    canvas.drawLine(Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, l), paint);
    canvas.drawLine(Offset(w - l, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), paint);
    canvas.drawLine(Offset(0, h), Offset(l, h), paint);
    canvas.drawLine(Offset(0, h - l), Offset(0, h), paint);
    canvas.drawLine(Offset(w - l, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - l), Offset(w, h), paint);
  }

  @override
  bool shouldRepaint(covariant _FocusIndicatorPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength;
  }
}
