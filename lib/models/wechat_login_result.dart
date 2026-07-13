class WechatLoginResult {
  const WechatLoginResult._({
    required this.loggedIn,
    this.bindToken,
  });

  const WechatLoginResult.loggedIn() : this._(loggedIn: true);

  const WechatLoginResult.bindPhoneRequired(String bindToken)
      : this._(loggedIn: false, bindToken: bindToken);

  const WechatLoginResult.failed() : this._(loggedIn: false);

  final bool loggedIn;
  final String? bindToken;

  bool get needBindPhone => bindToken != null && bindToken!.isNotEmpty;
}
