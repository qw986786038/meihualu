import 'package:geolocator/geolocator.dart';

abstract final class MediaCaptureSummary {
  static String formatRelativeTime(DateTime? time) {
    if (time == null) return '未知';

    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.isNegative) return '刚刚';

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';

    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  static String formatDistance(double? meters) {
    if (meters == null) return '距离未知';
    if (meters < 100) return '<100米';
    if (meters < 1000) return '${meters.round()}米';
    return '${(meters / 1000).toStringAsFixed(1)}公里';
  }

  static double? distanceMeters({
    required double? fromLatitude,
    required double? fromLongitude,
    required double? toLatitude,
    required double? toLongitude,
  }) {
    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  static double? parseCoordinate(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static DateTime? parseCaptureTime(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  static String buildLastCaptureLine({
    required DateTime? lastCaptureTime,
    required double? distanceMeters,
  }) {
    final timeText = formatRelativeTime(lastCaptureTime);
    final distanceText = formatDistance(distanceMeters);
    return '上次拍照:$timeText, $distanceText 查看路线 >';
  }
}
