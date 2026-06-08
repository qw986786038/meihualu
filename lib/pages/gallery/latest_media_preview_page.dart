import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';

/// 全屏预览相册中最近一张照片或视频。
class LatestMediaPreviewPage extends StatelessWidget {
  const LatestMediaPreviewPage({super.key, required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: asset.type == AssetType.video
            ? _VideoPreview(asset: asset)
            : _ImagePreview(asset: asset),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator(color: Colors.white);
        }
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const Text('无法加载图片', style: TextStyle(color: Colors.white70));
        }
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(file, fit: BoxFit.contain),
        );
      },
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.asset});

  final AssetEntity asset;

  Future<void> _openInGallery(BuildContext context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Gal.open();
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
        quality: 85,
      ),
      builder: (context, snapshot) {
        final thumb = snapshot.data;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (thumb != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(thumb, width: 280, fit: BoxFit.cover),
              )
            else
              const Icon(Icons.videocam, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              '视频请在系统相册中播放',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openInGallery(context),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('打开相册'),
            ),
          ],
        );
      },
    );
  }
}
