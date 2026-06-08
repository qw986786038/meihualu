import 'package:watermark_camera/widgets/WaterMark/watermark_data_keys.dart';

class WatermarkCoordinateFormatter {
  static String? format(
    double? latitude,
    double? longitude,
    String format, {
    bool withPrefix = true,
  }) {
    if (latitude == null || longitude == null) return null;

    final body = switch (format) {
      kCoordinateFormatDm =>
        '${_toDm(latitude, isLatitude: true)}, ${_toDm(longitude, isLatitude: false)}',
      kCoordinateFormatDms =>
        '${_toDms(latitude, isLatitude: true)}, ${_toDms(longitude, isLatitude: false)}',
      _ =>
        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
    };

    return withPrefix ? '经纬度 $body' : body;
  }

  static String formatAltitude(double? altitude) {
    if (altitude == null) return '无海拔信息';
    return '海拔 ${altitude.toStringAsFixed(1)}米';
  }

  static String _toDm(double value, {required bool isLatitude}) {
    final direction = isLatitude
        ? (value >= 0 ? 'N' : 'S')
        : (value >= 0 ? 'E' : 'W');
    final abs = value.abs();
    final degrees = abs.floor();
    final minutes = (abs - degrees) * 60;
    return '$degrees°${minutes.toStringAsFixed(2)}′$direction';
  }

  static String _toDms(double value, {required bool isLatitude}) {
    final direction = isLatitude
        ? (value >= 0 ? 'N' : 'S')
        : (value >= 0 ? 'E' : 'W');
    final abs = value.abs();
    final degrees = abs.floor();
    final minutesTotal = (abs - degrees) * 60;
    final minutes = minutesTotal.floor();
    final seconds = (minutesTotal - minutes) * 60;
    final secondsText = seconds.toStringAsFixed(2);
    return '$degrees°$minutes′$secondsText″$direction';
  }
}
