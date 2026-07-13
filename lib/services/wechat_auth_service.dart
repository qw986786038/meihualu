import 'dart:async' show Completer, TimeoutException, unawaited;

import 'package:fluwx/fluwx.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/config/api_config.dart';

class WeChatAuthException implements Exception {
  WeChatAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WeChatAuthService extends GetxService {
  final Fluwx _fluwx = Fluwx();
  bool _registered = false;

  @override
  void onInit() {
    super.onInit();
    unawaited(_registerApi());
  }

  Future<void> _registerApi() async {
    final universalLink = ApiConfig.weChatUniversalLink.trim();
    _registered = await _fluwx.registerApi(
      appId: ApiConfig.weChatAppId,
      doOnAndroid: true,
      doOnIOS: true,
      universalLink: universalLink.isEmpty ? null : universalLink,
    );
  }

  Future<String> requestAuthCode() async {
    if (!_registered) {
      await _registerApi();
    }
    if (!_registered) {
      throw WeChatAuthException('微信 SDK 初始化失败');
    }

    if (!await _fluwx.isWeChatInstalled) {
      throw WeChatAuthException('请先安装微信客户端');
    }

    final completer = Completer<String>();
    late final FluwxCancelable cancelable;

    void listener(WeChatResponse response) {
      if (response is! WeChatAuthResponse) return;
      cancelable.cancel();
      if (!response.isSuccessful) {
        final message = response.errStr?.trim();
        completer.completeError(
          WeChatAuthException(
            message != null && message.isNotEmpty ? message : '微信授权失败',
          ),
        );
        return;
      }

      final code = response.code?.trim();
      if (code == null || code.isEmpty) {
        completer.completeError(WeChatAuthException('微信授权失败，未返回 code'));
        return;
      }
      completer.complete(code);
    }

    cancelable = _fluwx.addSubscriber(listener);

    try {
      final sent = await _fluwx.authBy(
        which: NormalAuth(
          scope: 'snsapi_userinfo',
          state: 'watermark_camera_login',
        ),
      );
      if (!sent) {
        cancelable.cancel();
        throw WeChatAuthException('无法唤起微信，请稍后重试');
      }

      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          cancelable.cancel();
          throw WeChatAuthException('微信授权超时，请重试');
        },
      );
    } on WeChatAuthException {
      cancelable.cancel();
      rethrow;
    } on TimeoutException {
      cancelable.cancel();
      throw WeChatAuthException('微信授权超时，请重试');
    } catch (_) {
      cancelable.cancel();
      throw WeChatAuthException('微信授权失败，请稍后重试');
    }
  }
}
