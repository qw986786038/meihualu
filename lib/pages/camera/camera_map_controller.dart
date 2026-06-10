import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:geolocator/geolocator.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/services/amap_location_service.dart';

enum CameraMapType { standard, satellite }

class CameraMapController extends GetxController {
  final RxBool mapEnabled = true.obs;
  final Rx<CameraMapType> mapType = CameraMapType.standard.obs;
  final RxBool showShootingDirection = false.obs;
  final RxBool showRealTimeTrack = false.obs;
  final RxDouble scaleLevel = 0.5.obs;
  final RxDouble displaySize = 0.45.obs;
  final RxList<MapTrackPoint> trackPoints = <MapTrackPoint>[].obs;
  final RxnDouble headingDegrees = RxnDouble();

  Timer? _trackTimer;
  StreamSubscription<Position>? _headingSubscription;
  MapTrackPoint? _lastTrackPoint;

  static const int _minZoom = 10;
  static const int _maxZoom = 16;

  /// 比例尺 Z10–Z16，默认 Z13
  int get mapZoom {
    final value = scaleLevel.value.clamp(0.0, 1.0);
    return (_minZoom + value * (_maxZoom - _minZoom))
        .round()
        .clamp(_minZoom, _maxZoom);
  }

  Size mapSizeForPreview(double previewShortSide) {
    final side = mapSideForPreview(previewShortSide);
    return Size(side, side);
  }

  double mapSideForPreview(double previewShortSide) {
    final t = displaySize.value.clamp(0.0, 1.0);
    const minSide = 64.0;
    final maxSide = math.max(minSide, previewShortSide * 0.38);
    return minSide + t * (maxSide - minSide);
  }

  void setScaleLevel(double value) {
    final zoom = (_minZoom + value.clamp(0.0, 1.0) * (_maxZoom - _minZoom))
        .round()
        .clamp(_minZoom, _maxZoom);
    scaleLevel.value = (zoom - _minZoom) / (_maxZoom - _minZoom);
  }

  void setRealTimeTrackEnabled(bool enabled) {
    showRealTimeTrack.value = enabled;
    if (enabled) {
      _appendCurrentLocation(force: true);
      _startTrackTimer();
    } else {
      _stopTrackTimer();
    }
  }

  void setShootingDirectionEnabled(bool enabled) {
    showShootingDirection.value = enabled;
    if (enabled) {
      unawaited(_startHeadingListener());
    } else {
      _stopHeadingListener();
      headingDegrees.value = null;
    }
  }

  void clearTrack() {
    trackPoints.clear();
    _lastTrackPoint = null;
  }

  void _startTrackTimer() {
    _trackTimer?.cancel();
    _trackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!showRealTimeTrack.value) return;
      unawaited(_appendCurrentLocation());
      unawaited(Get.find<AMapLocationService>().refreshLocation());
    });
  }

  void _stopTrackTimer() {
    _trackTimer?.cancel();
    _trackTimer = null;
  }

  Future<void> _appendCurrentLocation({bool force = false}) async {
    final location = Get.find<AMapLocationService>().latestLocation.value;
    final lat = location?.latitude;
    final lng = location?.longitude;
    if (lat == null || lng == null) return;

    final point = MapTrackPoint(latitude: lat, longitude: lng);
    final last = _lastTrackPoint;
    if (!force && last != null) {
      final distance = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        lat,
        lng,
      );
      if (distance < 3) return;
    }

    _lastTrackPoint = point;
    trackPoints.add(point);
    if (trackPoints.length > 30) {
      trackPoints.removeRange(0, trackPoints.length - 30);
    }

    if (showShootingDirection.value && headingDegrees.value == null && last != null) {
      headingDegrees.value = _bearingBetween(
        last.latitude,
        last.longitude,
        lat,
        lng,
      );
    }
  }

  Future<void> _startHeadingListener() async {
    await _stopHeadingListener();

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _headingSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        distanceFilter: 2,
        accuracy: LocationAccuracy.high,
      ),
    ).listen((position) {
      if (!showShootingDirection.value) return;
      if (position.heading >= 0) {
        headingDegrees.value = position.heading;
        return;
      }
      final last = _lastTrackPoint;
      final lat = position.latitude;
      final lng = position.longitude;
      if (last != null) {
        headingDegrees.value = _bearingBetween(
          last.latitude,
          last.longitude,
          lat,
          lng,
        );
      }
    });
  }

  Future<void> _stopHeadingListener() async {
    await _headingSubscription?.cancel();
    _headingSubscription = null;
  }

  double _bearingBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  @override
  void onClose() {
    _stopTrackTimer();
    unawaited(_stopHeadingListener());
    super.onClose();
  }
}
