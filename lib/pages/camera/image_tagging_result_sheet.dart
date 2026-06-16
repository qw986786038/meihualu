import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/services/aliyun_image_tagging_service.dart';

const Color kImageTaggingPrimaryBlue = Color(0xFF2F7CF6);

Future<void> showImageTaggingResultSheet({
  required BuildContext context,
  required List<ImageTagResult> tags,
  Uint8List? previewBytes,
  AssetEntity? asset,
}) {
  assert(
    previewBytes != null || asset != null,
    'previewBytes 或 asset 至少提供一个',
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '识别结果',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildPreview(
                    previewBytes: previewBytes,
                    asset: asset,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '检测到以下物品：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              ...tags.map(_buildTagTile),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPreview({
  Uint8List? previewBytes,
  AssetEntity? asset,
}) {
  if (previewBytes != null) {
    return Image.memory(previewBytes, fit: BoxFit.cover);
  }
  return _AssetPreviewThumbnail(asset: asset!);
}

Widget _buildTagTile(ImageTagResult tag) {
  final confidenceText = '${tag.confidence.round()}%';
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.sell_outlined, color: kImageTaggingPrimaryBlue, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tag.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          confidenceText,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
}

class _AssetPreviewThumbnail extends StatelessWidget {
  const _AssetPreviewThumbnail({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize.square(800),
        quality: 80,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return ColoredBox(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.white54),
            ),
          );
        }
        return Image.memory(data, fit: BoxFit.cover);
      },
    );
  }
}
