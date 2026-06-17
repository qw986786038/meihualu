import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/services/aliyun_ocr_service.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

Future<void> showScreenTextResultSheet({
  required BuildContext context,
  required ScreenTextOcrResult result,
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
                '屏幕文字识别',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildPreview(
                    previewBytes: previewBytes,
                    asset: asset,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '识别到的广告文字：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: result.content),
                      );
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    result.content,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (result.words.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '分词明细',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                ...result.words.take(8).map(_buildWordTile),
              ],
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

Widget _buildWordTile(OcrWordResult word) {
  final confidenceText =
      word.confidence > 0 ? '${word.confidence.round()}%' : '';
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.text_fields, color: _kPrimaryBlue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            word.word,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (confidenceText.isNotEmpty)
          Text(
            confidenceText,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
