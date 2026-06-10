import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/utils/watermark_coordinate_formatter.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_data_keys.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';

class PhotoWatermarkContext {
  const PhotoWatermarkContext({
    required this.now,
    required this.address,
    required this.data,
    this.coordinateText,
    this.altitudeText,
  });

  final DateTime now;
  final String address;
  final Map<String, dynamic> data;
  final String? coordinateText;
  final String? altitudeText;
}

Future<PhotoWatermarkContext> resolvePhotoWatermarkContext(
  AssetEntity asset,
) async {
  final perPhotoData = <String, dynamic>{};
  var now = asset.createDateTime;

  if (asset.type == AssetType.image) {
    final file = await asset.file;
    if (file != null) {
      final meta = await WatermarkMetadata.readFromImagePath(file.path);
      if (meta != null) {
        now = _resolvePhotoDateTime(meta.data, asset.createDateTime);
        for (final key in <String>[
          'time',
          'date',
          'weekday',
          'latitude',
          'longitude',
          'altitude',
          'address',
          kWatermarkDataSelectedAddress,
        ]) {
          final value = meta.data[key];
          if (value != null) {
            perPhotoData[key] = value;
          }
        }
      }
    }
  }

  _ensurePhotoDateFields(perPhotoData, now);
  now = _resolvePhotoDateTime(perPhotoData, now);

  var address = watermarkString(perPhotoData, kWatermarkDataSelectedAddress);
  if (address.isEmpty) {
    address = (perPhotoData['address'] ?? '我在这里').toString();
  }

  String? coordinateText;
  final lat = perPhotoData['latitude'];
  final lng = perPhotoData['longitude'];
  if (lat is num && lng is num) {
    coordinateText = WatermarkCoordinateFormatter.format(
      lat.toDouble(),
      lng.toDouble(),
      kCoordinateFormatDecimal,
    );
  }

  String? altitudeText;
  final alt = perPhotoData['altitude'];
  if (alt is num) {
    altitudeText = WatermarkCoordinateFormatter.formatAltitude(alt.toDouble());
  }

  return PhotoWatermarkContext(
    now: now,
    address: address,
    data: perPhotoData,
    coordinateText: coordinateText,
    altitudeText: altitudeText,
  );
}

Map<String, dynamic> mergeSharedWatermarkSettings(
  Map<String, dynamic> shared,
  Map<String, dynamic> photoData,
) {
  final merged = Map<String, dynamic>.from(shared);
  for (final key in <String>[
    'time',
    'date',
    'weekday',
    'address',
    kWatermarkDataSelectedAddress,
    'latitude',
    'longitude',
    'altitude',
  ]) {
    if (photoData.containsKey(key) && photoData[key] != null) {
      merged[key] = photoData[key];
    }
  }
  return merged;
}

String? resolvePhotoCoordinateText(
  Map<String, dynamic> sharedSettings,
  Map<String, dynamic> photoData,
) {
  if (!watermarkBool(sharedSettings, kWatermarkDataShowCoordinate, fallback: true)) {
    return null;
  }
  final lat = photoData['latitude'];
  final lng = photoData['longitude'];
  if (lat is! num || lng is! num) return null;
  return WatermarkCoordinateFormatter.format(
    lat.toDouble(),
    lng.toDouble(),
    watermarkString(
      sharedSettings,
      kWatermarkDataCoordinateFormat,
      fallback: kCoordinateFormatDecimal,
    ),
  );
}

String? resolvePhotoAltitudeText(
  Map<String, dynamic> sharedSettings,
  Map<String, dynamic> photoData,
) {
  if (!watermarkBool(sharedSettings, kWatermarkDataShowAltitude, fallback: false)) {
    return null;
  }
  final alt = photoData['altitude'];
  if (alt is! num) return null;
  return WatermarkCoordinateFormatter.formatAltitude(alt.toDouble());
}

DateTime _resolvePhotoDateTime(
  Map<String, dynamic> data,
  DateTime fallback,
) {
  final dateStr = data['date']?.toString();
  final timeStr = data['time']?.toString();
  if (dateStr != null &&
      timeStr != null &&
      dateStr.isNotEmpty &&
      timeStr.isNotEmpty) {
    final parts = dateStr.split('-');
    final timeParts = timeStr.split(':');
    if (parts.length == 3 && timeParts.length >= 2) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (year != null &&
          month != null &&
          day != null &&
          hour != null &&
          minute != null) {
        return DateTime(year, month, day, hour, minute);
      }
    }
  }
  return fallback;
}

void _ensurePhotoDateFields(Map<String, dynamic> data, DateTime dateTime) {
  data.putIfAbsent(
    'time',
    () =>
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
  );
  data.putIfAbsent(
    'date',
    () =>
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}',
  );
  data.putIfAbsent(
    'weekday',
    () => const [
      '星期一',
      '星期二',
      '星期三',
      '星期四',
      '星期五',
      '星期六',
      '星期日',
    ][dateTime.weekday - 1],
  );
}
