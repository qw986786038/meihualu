/// 用户个人信息。
class UserInfo {
  const UserInfo({
    required this.userId,
    required this.phone,
    this.userName,
    this.nickName,
    this.email,
    this.sex,
    this.avatarUrl,
  });

  final String userId;
  final String phone;
  final String? userName;
  final String? nickName;
  final String? email;
  final String? sex;
  final String? avatarUrl;

  String get displayName {
    final nick = nickName?.trim();
    if (nick != null && nick.isNotEmpty) return nick;
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (phone.length >= 4) {
      return '用户${phone.substring(phone.length - 4)}';
    }
    return '用户';
  }

  String get sexLabel {
    switch (sex) {
      case '1':
        return '男';
      case '2':
        return '女';
      default:
        return '未设置';
    }
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      userName: json['userName'] as String?,
      nickName: json['nickName'] as String?,
      email: json['email'] as String?,
      sex: json['sex']?.toString(),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  UserInfo copyWith({
    String? userId,
    String? phone,
    String? userName,
    String? nickName,
    String? email,
    String? sex,
    String? avatarUrl,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      userName: userName ?? this.userName,
      nickName: nickName ?? this.nickName,
      email: email ?? this.email,
      sex: sex ?? this.sex,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
