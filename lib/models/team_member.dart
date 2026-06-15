enum TeamMemberRole { owner, member }

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.avatarText,
    required this.isSelf,
    this.role = TeamMemberRole.member,
  });

  final String id;
  final String name;
  final String avatarText;
  final bool isSelf;
  final TeamMemberRole role;

  String get roleLabel =>
      role == TeamMemberRole.owner ? '主管理员' : '成员';
}
