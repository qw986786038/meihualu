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

/// 空间素材缩略图，支持视频标识与防伪认证角标。
class SpaceMediaThumbnail extends StatelessWidget {
  const SpaceMediaThumbnail({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholderColor = const Color(0xFF2F2F2F),
    this.isVideo = false,
    this.proofMark = false,
    this.videoIconSize = 24,
    this.bottomOverlay,
  });

  final String url;
  final BoxFit fit;
  final Color placeholderColor;
  final bool isVideo;
  final bool proofMark;
  final double videoIconSize;
  final Widget? bottomOverlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SpaceMediaImage(
          url: url,
          fit: fit,
          placeholderColor: placeholderColor,
        ),
        if (isVideo)
          Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: videoIconSize,
            ),
          ),
        if (proofMark) const SpaceProofMarkBadge(),
        ?bottomOverlay,
      ],
    );
  }
}

/// 防伪认证通过标识，显示在缩略图右上角。
class SpaceProofMarkBadge extends StatelessWidget {
  const SpaceProofMarkBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Color(0xFF34C759),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
