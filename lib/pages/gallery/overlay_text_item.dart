import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:watermark_camera/pages/gallery/add_text_presets.dart';
import 'package:watermark_camera/pages/gallery/overlay_text_input_dialog.dart';

const double _kControlInset = 20;
const double _kControlSize = 30;

class OverlayTextItem extends StatelessWidget {
  const OverlayTextItem({
    super.key,
    required this.data,
    required this.selected,
    required this.updateData,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final bool selected;
  final ValueChanged<Map<String, dynamic>> updateData;
  final VoidCallback onDelete;

  Future<void> _editText(BuildContext context) async {
    final result = await showOverlayTextInputDialog(
      context,
      initialText: overlayTextFromData(data),
      title: '编辑文字',
    );
    if (result == null || result.isEmpty) return;
    updateData({...data, kOverlayTextContent: result});
  }

  void _rotateBy(double delta) {
    final next = overlayRotationFromData(data) + delta;
    updateData({...data, kOverlayTextRotation: next});
  }

  @override
  Widget build(BuildContext context) {
    final rotation = overlayRotationFromData(data);
    final style = addTextStyleFromData(data);
    final text = overlayTextFromData(data);

    return Padding(
      padding: selected
          ? const EdgeInsets.all(_kControlInset)
          : EdgeInsets.zero,
      child: Transform.rotate(
        angle: rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onDoubleTap: () => _editText(context),
              child: _StyledTextPreview(style: style, text: text),
            ),
            if (selected) ...[
              Positioned(
                top: 0,
                left: 0,
                child: _ControlButton(
                  icon: Icons.close,
                  backgroundColor: Colors.red,
                  onTap: onDelete,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _RotateHandle(
                  onRotate: (delta) => _rotateBy(delta),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RotateHandle extends StatelessWidget {
  const _RotateHandle({required this.onRotate});

  final ValueChanged<double> onRotate;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {},
        onPanUpdate: (details) => onRotate(details.delta.dx * 0.02),
        child: const _ControlButton(
          icon: Icons.rotate_right,
          backgroundColor: Color(0xFF2F7CF6),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.backgroundColor,
    this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: _kControlSize,
          height: _kControlSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _StyledTextPreview extends StatelessWidget {
  const _StyledTextPreview({required this.style, required this.text});

  final AddTextStyle style;
  final String text;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      AddTextStyle.label => _label(),
      AddTextStyle.annotation => _annotation(),
      AddTextStyle.outline => _outline(),
      AddTextStyle.background => _background(),
      AddTextStyle.dimension => _dimension(),
      AddTextStyle.artistic => _artistic(),
      AddTextStyle.location => _withIcon(Icons.location_on, Colors.red),
      AddTextStyle.clockIn => _withIcon(Icons.check_box, Colors.green),
      AddTextStyle.problem => _problem(),
      AddTextStyle.frame => _frame(),
      AddTextStyle.hazard => _hazard(),
      AddTextStyle.banner => _banner(),
      AddTextStyle.badgeBefore => _badge(const Color(0xFFFFC107), Colors.black),
      AddTextStyle.badgeAfter => _badge(const Color(0xFF43A047), Colors.white),
      AddTextStyle.stampPass => _stamp(const Color(0xFF43A047), '内部自检'),
      AddTextStyle.stampFail => _stamp(const Color(0xFFE53935), '内部自检'),
      AddTextStyle.stampRecord => _stampRecord(),
      AddTextStyle.sprint => _withIcon(Icons.front_hand, Colors.white),
      AddTextStyle.notebook => _notebook(),
    };
  }

  Widget _label() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(text, style: _textStyle(Colors.white, 14)),
        ],
      ),
    );
  }

  Widget _annotation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: _textStyle(const Color(0xFFE53935), 16, bold: true)),
        const Icon(Icons.north_west, color: Color(0xFFE53935), size: 18),
      ],
    );
  }

  Widget _outline() {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white,
          ),
        ),
        Text(
          text,
          style: _textStyle(const Color(0xFFE53935), 18, bold: true),
        ),
      ],
    );
  }

  Widget _background() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: const Color(0xFFE53935),
      child: Text(text, style: _textStyle(Colors.white, 16, bold: true)),
    );
  }

  Widget _dimension() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _verticalBar(),
        const SizedBox(width: 6),
        Text(text, style: _textStyle(const Color(0xFFE53935), 15, bold: true)),
        const SizedBox(width: 6),
        _verticalBar(),
      ],
    );
  }

  Widget _verticalBar() {
    return Container(
      width: 2,
      height: 22,
      color: const Color(0xFFE53935),
    );
  }

  Widget _artistic() {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        shadows: [
          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
    );
  }

  Widget _withIcon(IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: _textStyle(Colors.white, 15, bold: true)),
      ],
    );
  }

  Widget _problem() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 4),
          Text(text, style: _textStyle(const Color(0xFFE53935), 14, bold: true)),
        ],
      ),
    );
  }

  Widget _frame() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(text, style: _textStyle(Colors.white, 15, bold: true)),
    );
  }

  Widget _hazard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFF1565C0),
          child: Text(text, style: _textStyle(Colors.white, 15, bold: true)),
        ),
        Container(
          height: 8,
          width: math.max(80, text.length * 16.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFC107), Color(0xFF212121)],
              stops: [0.5, 0.5],
              tileMode: TileMode.repeated,
            ),
          ),
        ),
      ],
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        border: Border(
          top: BorderSide(color: Color(0xFF1565C0), width: 3),
          bottom: BorderSide(color: Color(0xFF1565C0), width: 3),
        ),
      ),
      child: Text(text, style: _textStyle(Colors.black, 15, bold: true)),
    );
  }

  Widget _badge(Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build, size: 14),
          const SizedBox(width: 4),
          Text(text, style: _textStyle(fg, 14, bold: true)),
        ],
      ),
    );
  }

  Widget _stamp(Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: _textStyle(color, 18, bold: true)),
          Text(subtitle, style: _textStyle(color, 10)),
        ],
      ),
    );
  }

  Widget _stampRecord() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1565C0), width: 2),
      ),
      child: Text(text, style: _textStyle(const Color(0xFFE53935), 16, bold: true)),
    );
  }

  Widget _notebook() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: _textStyle(Colors.black, 15, bold: true)),
          Text('NORMAL', style: _textStyle(Colors.grey.shade600, 10)),
        ],
      ),
    );
  }

  TextStyle _textStyle(Color color, double size, {bool bold = false}) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
  }
}

/// 加字模板在选择面板中的缩略预览。
class AddTextPresetPreview extends StatelessWidget {
  const AddTextPresetPreview({super.key, required this.preset});

  final AddTextPreset preset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _StyledTextPreview(
          style: preset.style,
          text: preset.defaultText,
        ),
      ),
    );
  }
}
