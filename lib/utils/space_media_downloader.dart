import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';

class SpaceMediaDownloadItem {
  const SpaceMediaDownloadItem({
    required this.url,
    required this.isVideo,
    this.fileName,
  });

  final String url;
  final bool isVideo;
  final String? fileName;
}

abstract final class SpaceMediaDownloader {
  static const _albumName = '媒花录';

  static Future<bool> downloadToGallery({
    required String ossUrl,
    required bool isVideo,
    String? fileName,
  }) async {
    final url = _resolveUrl(ossUrl);
    if (url.isEmpty) return false;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (!file.existsSync()) return false;
      return GallerySaver.savePath(
        url,
        isVideo: isVideo,
        album: _albumName,
      );
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      return GallerySaver.saveBytes(
        response.bodyBytes,
        isVideo: isVideo,
        album: _albumName,
        fileName: fileName,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<int> downloadMany(List<SpaceMediaDownloadItem> items) async {
    var successCount = 0;
    for (final item in items) {
      final ok = await downloadToGallery(
        ossUrl: item.url,
        isVideo: item.isVideo,
        fileName: item.fileName,
      );
      if (ok) successCount++;
    }
    return successCount;
  }

  static String _resolveUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return ApiConfig.resolveAssetUrl(value);
  }
}
