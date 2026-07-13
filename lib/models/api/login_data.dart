class LoginData {
  const LoginData({
    this.scope,
    this.openid,
    this.userId,
    this.isRegister,
    this.accessToken,
    this.refreshToken,
    this.expireIn,
    this.refreshExpireIn,
    this.clientId,
    this.needBindPhone,
    this.bindToken,
  });

  final String? scope;
  final String? openid;
  final String? userId;
  final bool? isRegister;
  final String? accessToken;
  final String? refreshToken;
  final int? expireIn;
  final int? refreshExpireIn;
  final String? clientId;
  final bool? needBindPhone;
  final String? bindToken;

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      scope: json['scope'] as String?,
      openid: json['openid'] as String?,
      userId: json['userId']?.toString(),
      isRegister: json['isRegister'] as bool?,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expireIn: json['expire_in'] as int?,
      refreshExpireIn: json['refresh_expire_in'] as int?,
      clientId: json['client_id'] as String?,
      needBindPhone: _parseBool(json['needBindPhone']),
      bindToken: json['bindToken']?.toString(),
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }
}
