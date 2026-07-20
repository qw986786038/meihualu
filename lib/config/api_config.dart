/// 后端 API 公共配置。
abstract final class ApiConfig {
  static const String baseUrl = 'http://192.168.5.23:8089/watermark-camera/';

  /// 客户端 ID，登录等接口共用。
  static const String clientId = '907e91bbea3b58d25eb99fe9a406b2e0';

  /// 密码登录 grantType 固定值。
  static const String grantTypePassword = 'password';

  /// 验证码登录 grantType 固定值。
  static const String grantTypeSms = 'sms';

  /// 微信开放平台 AppID（AppSecret 仅保存在服务端）。
  static const String weChatAppId = 'wxb6ff0bb17edccf78';

  /// iOS Universal Link，需与微信开放平台配置一致后方可使用微信登录。
  static const String weChatUniversalLink = '';

  /// 文件上传接口路径。
  static const String uploadPath = 'resource/oss/upload';

  /// 将接口返回的相对路径转为可访问地址。
  static String resolveAssetUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (value.startsWith('/')) {
      final hostEnd = root.lastIndexOf('/');
      final host = hostEnd > 'http://'.length
          ? root.substring(0, hostEnd)
          : root;
      return '$host$value';
    }
    return '$root/$value';
  }
}
