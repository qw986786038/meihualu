import 'dart:io';

import 'package:flutter/material.dart';

class SpaceMediaImage extends StatelessWidget {
  const SpaceMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFF2F2F2F),
  });

  final String url;
  final BoxFit fit;
  final Color placeholderColor;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return _placeholder();
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    final file = File(trimmed);
    if (file.existsSync()) {
      return Image.file(file, fit: fit);
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: placeholderColor,
      alignment: Alignment.center,
      child: Icon(Icons.photo_camera_outlined, color: Colors.grey.shade500, size: 36),
    );
  }
}
