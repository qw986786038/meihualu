class Team {
  const Team({
    required this.id,
    required this.name,
    required this.industryType,
    required this.teamCode,
    this.brandImagePath,
    this.syncEnabled = true,
  });

  final String id;
  final String name;
  final String industryType;
  final String teamCode;
  final String? brandImagePath;
  final bool syncEnabled;

  Team copyWith({
    String? id,
    String? name,
    String? industryType,
    String? teamCode,
    String? brandImagePath,
    bool? syncEnabled,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      industryType: industryType ?? this.industryType,
      teamCode: teamCode ?? this.teamCode,
      brandImagePath: brandImagePath ?? this.brandImagePath,
      syncEnabled: syncEnabled ?? this.syncEnabled,
    );
  }
}

const List<Team> kMockJoinableTeams = [
  Team(
    id: 'mock_team_1',
    name: '演示建筑工程团队',
    industryType: '房屋建筑业',
    teamCode: '888888',
  ),
  Team(
    id: 'mock_team_2',
    name: '演示物业管理团队',
    industryType: '物业管理',
    teamCode: '666666',
  ),
];
