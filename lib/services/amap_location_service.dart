import 'package:fl_amap/fl_amap.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:getx_plus/getx_plus.dart';

class AMapLocationService extends GetxService {
  static const String _androidKey = "5f93acf2447e97cae3b039430c873272";
  static const String _iosKey = String.fromEnvironment('AMAP_IOS_KEY');
  static const String _locatingText = '定位中...';
  static const String _missingKeyText = '请配置高德 Key';
  static const String _serviceDisabledText = '请开启定位服务';
  static const String _permissionDeniedText = '定位权限未开启';
  static const String _permissionDeniedForeverText = '定位权限被永久拒绝';
  static const String _locationFailedText = '定位失败';

  final RxString watermarkAddress = _locatingText.obs;
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
      watermarkAddress.value = _formatAddress(location);
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
      watermarkAddress.value = '高德定位初始化失败';
      return false;
    }

    _pluginInitialized = true;
    return true;
  }

  String _formatAddress(AMapLocation location) {
    final address = location.address?.trim();
    final poiName = location.poiName?.trim();
    if (address != null && address.isNotEmpty) {
      if (poiName != null && poiName.isNotEmpty && !address.contains(poiName)) {
        return '$address · $poiName';
      }
      return address;
    }

    final parts = <String>[];
    void addPart(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      if (parts.isNotEmpty && parts.last == text) return;
      parts.add(text);
    }

    addPart(location.province);
    addPart(location.city);
    addPart(location.district);
    addPart(location.street);
    addPart(location.streetNum);
    addPart(poiName);

    if (parts.isEmpty) return _locationFailedText;
    return parts.join();
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
