import 'dart:async' show unawaited;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/utils/rsa_key_pair_helper.dart';

/// App 首次安装（本地尚无设备密钥）时生成 RSA 密钥并注册公钥。
class DeviceKeyService extends GetxService {
  static const _deviceIdKey = 'device_key_device_id';
  static const _publicKeyKey = 'device_key_public_key';
  static const _privateKeyKey = 'device_key_private_key';
  static const _registeredKey = 'device_key_registered';

  String? _deviceId;
  String? _publicKeyBase64;
  String? _privateKeyBase64;
  bool _registered = false;

  String? get deviceId => _deviceId;
  String? get publicKeyBase64 => _publicKeyBase64;
  String? get privateKeyBase64 => _privateKeyBase64;
  bool get isRegistered => _registered;

  @override
  void onInit() {
    super.onInit();
    unawaited(ensureRegistered());
  }

  /// 仅保证本地密钥可用（不强制已注册成功）。
  Future<bool> ensureKeysReady() async {
    try {
      await _ensureLocalKeys();
      return (_deviceId?.isNotEmpty ?? false) &&
          (_privateKeyBase64?.isNotEmpty ?? false);
    } catch (error, stackTrace) {
      debugPrint('ensureKeysReady error: $error\n$stackTrace');
      return false;
    }
  }

  /// 确保本地密钥存在，并在未注册成功时调用 `/key/keyRegister`。
  Future<bool> ensureRegistered() async {
    try {
      await _ensureLocalKeys();
      if (_registered) return true;

      final deviceId = _deviceId;
      final publicKey = _publicKeyBase64;
      if (deviceId == null ||
          deviceId.isEmpty ||
          publicKey == null ||
          publicKey.isEmpty) {
        return false;
      }

      final response = await Get.find<SpaceApiService>().registerPublicKey(
        deviceId: deviceId,
        publicKey: publicKey,
      );
      if (!response.isSuccess) {
        debugPrint('keyRegister failed: ${response.msg}');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_registeredKey, true);
      _registered = true;
      return true;
    } catch (error, stackTrace) {
      debugPrint('keyRegister error: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> _ensureLocalKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    _publicKeyBase64 = prefs.getString(_publicKeyKey);
    _privateKeyBase64 = prefs.getString(_privateKeyKey);
    _registered = prefs.getBool(_registeredKey) ?? false;

    final hasKeys = (_deviceId?.isNotEmpty ?? false) &&
        (_publicKeyBase64?.isNotEmpty ?? false) &&
        (_privateKeyBase64?.isNotEmpty ?? false);
    if (hasKeys) return;

    final pair = await compute(_generateKeyPairIsolate, null);
    final deviceId = _newDeviceId();

    await prefs.setString(_deviceIdKey, deviceId);
    await prefs.setString(_publicKeyKey, pair.publicKeyBase64);
    await prefs.setString(_privateKeyKey, pair.privateKeyBase64);
    await prefs.setBool(_registeredKey, false);

    _deviceId = deviceId;
    _publicKeyBase64 = pair.publicKeyBase64;
    _privateKeyBase64 = pair.privateKeyBase64;
    _registered = false;
  }

  static String _newDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

RsaGeneratedKeyPair _generateKeyPairIsolate(void _) {
  return RsaKeyPairHelper.generate();
}
