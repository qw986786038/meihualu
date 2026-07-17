import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/team_member.dart';

class TeamMemberInfo {
  const TeamMemberInfo({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.nickName,
    required this.phone,
    this.sex = '',
    this.avatarUrl = '',
    this.memberRole = 2,
  });

  final String id;
  final String spaceId;
  final String userId;
  final String nickName;
  final String phone;
  final String sex;
  final String avatarUrl;

  /// 成员角色：1 管理员，2 普通成员。
  final int memberRole;

  factory TeamMemberInfo.fromJson(Map<String, dynamic> json) {
    return TeamMemberInfo(
      id: '${json['id'] ?? ''}',
      spaceId: '${json['spaceId'] ?? ''}',
      userId: '${json['userId'] ?? ''}',
      nickName: json['nickName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      sex: json['sex']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      memberRole: _asInt(json['memberRole']) ?? 2,
    );
  }

  bool get isAdmin => memberRole == 1;

  TeamMember toTeamMember({required String selfUserId}) {
    final name = nickName.trim().isNotEmpty ? nickName.trim() : '成员';
    return TeamMember(
      id: userId,
      name: name,
      avatarText: name.substring(0, 1),
      isSelf: userId == selfUserId,
      role: isAdmin ? TeamMemberRole.owner : TeamMemberRole.member,
    );
  }

  String get resolvedAvatarUrl {
    final value = avatarUrl.trim();
    if (value.isEmpty) return '';
    return ApiConfig.resolveAssetUrl(value);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
