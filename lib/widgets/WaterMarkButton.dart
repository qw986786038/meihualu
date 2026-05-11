import 'package:flutter/material.dart';

class WaterMarkButton extends StatelessWidget {
  const WaterMarkButton({super.key, required this.onTap, this.width = 45, this.height = 45});

  final GestureTapCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Icon(Icons.branding_watermark_outlined, size: 28, color: Colors.white.withValues(alpha: 1))),
        ),
      ),
    );
  }
}
