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
    );
  }
}
