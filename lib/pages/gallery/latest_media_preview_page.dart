import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';

/// 全屏预览相册中最近一张照片或视频；也可直接预览本地文件。
class LatestMediaPreviewPage extends StatelessWidget {
  const LatestMediaPreviewPage({
    super.key,
    this.asset,
    this.filePath,
    this.isVideo = false,
  }) : assert(asset != null || filePath != null);

  final AssetEntity? asset;
  final String? filePath;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final showVideo = asset != null
        ? asset!.type == AssetType.video
        : isVideo;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: showVideo
            ? (asset != null
                ? _VideoPreview(asset: asset!)
                : const Text(
                    '视频请在系统相册中播放',
                    style: TextStyle(color: Colors.white70),
                  ))
            : _ImagePreview(asset: asset, filePath: filePath),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.asset, this.filePath});

  final AssetEntity? asset;
  final String? filePath;

  Future<File?> _resolveFile() async {
    if (filePath != null) {
      final file = File(filePath!);
      return file.existsSync() ? file : null;
    }
    return asset?.file;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _resolveFile(),
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
