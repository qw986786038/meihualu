import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/team_member.dart';

class TeamMemberInfo {
  const TeamMemberInfo({
    required this.userId,
    required this.nickName,
    required this.sex,
    required this.phone,
    required this.avatarUrl,
  });

  final String userId;
  final String nickName;
  final String sex;
  final String phone;
  final String avatarUrl;

  factory TeamMemberInfo.fromJson(Map<String, dynamic> json) {
    return TeamMemberInfo(
      userId: '${json['userId'] ?? ''}',
      nickName: json['nickName'] as String? ?? '',
      sex: json['sex'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  TeamMember toTeamMember({required String selfUserId}) {
    final name = nickName.trim().isNotEmpty ? nickName.trim() : '成员';
    return TeamMember(
      id: userId,
      name: name,
      avatarText: name.substring(0, 1),
      isSelf: userId == selfUserId,
    );
  }

  String get resolvedAvatarUrl {
    final value = avatarUrl.trim();
    if (value.isEmpty) return '';
    return ApiConfig.resolveAssetUrl(value);
  }
}
