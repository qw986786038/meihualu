import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:fl_amap/fl_amap.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:http/http.dart' as http;

class MapTrackPoint {
  const MapTrackPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class AMapLocationService extends GetxService {
  static const String _androidKey = "21c92e09642734eba87362262756398e";
  static const String _iosKey = String.fromEnvironment('AMAP_IOS_KEY');
  static const String _webServiceKey = '76092dcf4ed5620620cd5a7e430d0fb0';
  static const String _locatingText = '定位中...';
  static const String _missingKeyText = '请配置高德 Key';
  static const String _serviceDisabledText = '请开启定位服务';
  static const String _permissionDeniedText = '定位权限未开启';
  static const String _permissionDeniedForeverText = '定位权限被永久拒绝';
  static const String _locationFailedText = '定位失败';

  final RxString watermarkAddress = _locatingText.obs;
  final RxString watermarkWeather = ''.obs;
  final RxString watermarkTemperature = ''.obs;
  final RxList<String> nearbyRecommendations = <String>[].obs;
  final RxBool isLocating = false.obs;
  final Rxn<AMapLocation> latestLocation = Rxn<AMapLocation>();

  bool _hasWarmedUp = false;
  bool _pluginInitialized = false;

  Future<void> warmupLocation() async {
    if (_hasWarmedUp) return;
    _hasWarmedUp = true;
    await refreshLocation();
  }

  Future<void> refreshLocation() async {
    if (!_isSupportedPlatform) {
      watermarkAddress.value = '当前平台不支持高德定位';
      return;
    }
    if (isLocating.value) return;

    isLocating.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        watermarkAddress.value = _serviceDisabledText;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        watermarkAddress.value = _permissionDeniedText;
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        watermarkAddress.value = _permissionDeniedForeverText;
        return;
      }

      final ready = await _ensurePluginInitialized();
      if (!ready) return;

      watermarkAddress.value = _locatingText;
      watermarkWeather.value = '';
      watermarkTemperature.value = '';
      nearbyRecommendations.clear();
      final location = await FlAMapLocation().getLocation(
        optionForAndroid: const AMapLocationOptionForAndroid(
          locationMode: AMapLocationMode.heightAccuracy,
          locationProtocol: AMapLocationProtocol.https,
          locationPurpose: AMapLocationPurpose.signIn,
          geoLanguage: GeoLanguage.zh,
          needAddress: true,
          onceLocationLatest: true,
          mockEnable: false,
        ),
        optionForIOS: const AMapLocationOptionForIOS(
          withReGeocode: true,
          reGeocodeLanguage: GeoLanguage.zh,
          locationAccuracyMode: AMapLocationAccuracyMode.fullAndReduceAccuracy,
          desiredAccuracy:
              CLLocationAccuracy.kCLLocationAccuracyNearestTenMeters,
          detectRiskOfFakeLocation: true,
        ),
      );
      if (location == null) {
        watermarkAddress.value = _locationFailedText;
        return;
      }

      latestLocation.value = location;
      watermarkAddress.value = _formatBriefAddress(location);
      nearbyRecommendations.assignAll(_buildLocalRecommendations(location));
      unawaited(_fetchWeather(location.adCode));
      unawaited(_fetchNearbyRecommendations(location));
    } catch (e, st) {
      assert(() {
        debugPrint('AMap location failed: $e\n$st');
        return true;
      }());
      watermarkAddress.value = _locationFailedText;
    } finally {
      isLocating.value = false;
    }
  }

  Future<bool> _ensurePluginInitialized() async {
    if (_pluginInitialized) return true;

    final currentKey = _isAndroid ? _androidKey : _iosKey;
    if (currentKey.isEmpty) {
      watermarkAddress.value = _missingKeyText;
      return false;
    }

    final keyReady = await FlAMap().setAMapKey(
      iosKey: _iosKey,
      androidKey: _androidKey,
      isAgree: true,
      isContains: true,
      isShow: true,
    );
    if (!keyReady) {
      watermarkAddress.value = '高德初始化失败';
      return false;
    }

    final initialized = await FlAMapLocation().initialize(
      optionForAndroid: const AMapLocationOptionForAndroid(
        locationMode: AMapLocationMode.heightAccuracy,
        locationProtocol: AMapLocationProtocol.https,
        locationPurpose: AMapLocationPurpose.signIn,
        geoLanguage: GeoLanguage.zh,
        needAddress: true,
        onceLocationLatest: true,
        mockEnable: false,
      ),
      optionForIOS: const AMapLocationOptionForIOS(
        withReGeocode: true,
        reGeocodeLanguage: GeoLanguage.zh,
        locationAccuracyMode: AMapLocationAccuracyMode.fullAndReduceAccuracy,
        desiredAccuracy: CLLocationAccuracy.kCLLocationAccuracyNearestTenMeters,
        detectRiskOfFakeLocation: true,
      ),
    );
    if (!initialized) {
      watermarkAddress.value = '高德定位初始化失败，';
      return false;
    }

    _pluginInitialized = true;
    return true;
  }

  String formatBriefAddress(AMapLocation location, {String? nearbyOverride}) {
    final parts = <String>[];
    void addPart(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (parts.isNotEmpty && parts.last == text) return;
      parts.add(text);
    }

    addPart(location.city);
    addPart(location.district);
    var brief = parts.join();
    if (brief.isEmpty) {
      addPart(location.province);
      brief = parts.join();
    }

    final nearby = nearbyOverride?.trim().isNotEmpty == true
        ? nearbyOverride!.trim()
        : _formatNearbyDetail(location, brief);
    if (brief.isNotEmpty && nearby != null) return '$brief · $nearby';
    if (brief.isNotEmpty) return brief;

    return _locationFailedText;
  }

  List<String> _buildLocalRecommendations(AMapLocation location) {
    final results = <String>[];
    void add(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (results.contains(text)) return;
      results.add(text);
    }

    add(_formatBriefAddress(location));

    final poi = location.poiName?.trim();
    if (poi != null && poi.isNotEmpty) {
      add(formatBriefAddress(location, nearbyOverride: poi));
    }

    final aoi = location.aoiName?.trim();
    if (aoi != null && aoi.isNotEmpty) {
      add(formatBriefAddress(location, nearbyOverride: aoi));
    }

    final street = location.street?.trim();
    final streetNum = location.streetNum?.trim();
    if (street != null && street.isNotEmpty) {
      add(formatBriefAddress(
        location,
        nearbyOverride: streetNum == null || streetNum.isEmpty
            ? street
            : '$street$streetNum',
      ));
    }

    final fullAddress = location.address?.trim();
    if (fullAddress != null && fullAddress.isNotEmpty) {
      add(fullAddress);
    }

    return results;
  }

  Future<void> _fetchNearbyRecommendations(AMapLocation location) async {
    final latitude = location.latitude;
    final longitude = location.longitude;
    if (latitude == null || longitude == null) return;

    try {
      final uri = Uri.https('restapi.amap.com', '/v3/place/around', {
        'key': _webServiceKey,
        'location': '$longitude,$latitude',
        'radius': '1000',
        'offset': '8',
        'page': '1',
        'extensions': 'base',
        'output': 'JSON',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body is! Map) return;
      if (body['status']?.toString() != '1') return;

      final pois = body['pois'];
      if (pois is! List) return;

      final merged = List<String>.from(nearbyRecommendations);
      void add(String? value) {
        final text = value?.trim();
        if (text == null || text.isEmpty) return;
        if (merged.contains(text)) return;
        merged.add(text);
      }

      for (final raw in pois) {
        if (raw is! Map) continue;
        final name = raw['name']?.toString();
        if (name == null || name.isEmpty) continue;
        add(formatBriefAddress(location, nearbyOverride: name));
      }

      nearbyRecommendations.assignAll(merged);
    } catch (e, st) {
      assert(() {
        debugPrint('AMap nearby POI failed: $e\n$st');
        return true;
      }());
    }
  }

  String _formatBriefAddress(AMapLocation location) {
    return formatBriefAddress(location);
  }

  String? _formatNearbyDetail(AMapLocation location, String brief) {
    final poi = location.poiName?.trim();
    if (poi != null && poi.isNotEmpty && !brief.contains(poi)) {
      return poi;
    }

    final street = location.street?.trim();
    final streetNum = location.streetNum?.trim();
    final streetParts = <String>[];
    if (street != null && street.isNotEmpty) streetParts.add(street);
    if (streetNum != null && streetNum.isNotEmpty) streetParts.add(streetNum);
    final streetText = streetParts.join();
    if (streetText.isNotEmpty && !brief.contains(streetText)) {
      return streetText;
    }

    final aoi = location.aoiName?.trim();
    if (aoi != null && aoi.isNotEmpty && !brief.contains(aoi)) {
      return aoi;
    }

    return null;
  }

  Future<void> _fetchWeather(String? adCode) async {
    final code = adCode?.trim();
    if (code == null || code.isEmpty) {
      watermarkWeather.value = '';
      watermarkTemperature.value = '';
      return;
    }

    try {
      final uri = Uri.https('restapi.amap.com', '/v3/weather/weatherInfo', {
        'city': code,
        'key': _webServiceKey,
        'extensions': 'base',
        'output': 'JSON',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body is! Map) return;
      if (body['status']?.toString() != '1') return;

      final lives = body['lives'];
      if (lives is! List || lives.isEmpty) return;

      final live = lives.first;
      if (live is! Map) return;

      watermarkWeather.value = live['weather']?.toString().trim() ?? '';
      watermarkTemperature.value = live['temperature']?.toString().trim() ?? '';
    } catch (e, st) {
      assert(() {
        debugPrint('AMap weather failed: $e\n$st');
        return true;
      }());
    }
  }

  String buildStaticMapUrl({
    required double longitude,
    required double latitude,
    int zoom = 16,
    int width = 120,
    int height = 90,
    List<MapTrackPoint>? trackPoints,
  }) {
    final location = '$longitude,$latitude';
    final size = '${width.clamp(40, 1024)}*${height.clamp(40, 1024)}';
    final markers = Uri.encodeComponent('mid,,A:$location');
    final buffer = StringBuffer(
      'https://restapi.amap.com/v3/staticmap'
      '?location=$location'
      '&zoom=${zoom.clamp(3, 18)}'
      '&size=$size'
      '&markers=$markers'
      '&scale=2'
      '&key=$_webServiceKey',
    );
    final path = _encodeTrackPath(trackPoints);
    if (path != null) {
      buffer.write('&paths=$path');
    }
    return buffer.toString();
  }

  String? _encodeTrackPath(List<MapTrackPoint>? trackPoints) {
    if (trackPoints == null || trackPoints.length < 2) return null;
    final coords = trackPoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    return Uri.encodeComponent('5,0x0088FF,1,,:$coords');
  }

  @override
  void onClose() {
    if (_pluginInitialized) {
      FlAMapLocation().dispose();
    }
    super.onClose();
  }

  bool get _isSupportedPlatform => !kIsWeb && (_isAndroid || _isIOS);

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
}
