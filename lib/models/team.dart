class Team {
  const Team({
    required this.id,
    required this.name,
    required this.industryType,
    required this.teamCode,
    this.brandImagePath,
    this.syncEnabled = true,
    this.photoNum = 0,
    this.todayUploadNum = 0,
    this.todayUploadPersonNum = 0,
    this.todaySelfUploadNum = 0,
  });

  final String id;
  final String name;
  final String industryType;
  final String teamCode;
  final String? brandImagePath;
  final bool syncEnabled;
  final int photoNum;
  final int todayUploadNum;
  final int todayUploadPersonNum;
  final int todaySelfUploadNum;

  Team copyWith({
    String? id,
    String? name,
    String? industryType,
    String? teamCode,
    String? brandImagePath,
    bool? syncEnabled,
    int? photoNum,
    int? todayUploadNum,
    int? todayUploadPersonNum,
    int? todaySelfUploadNum,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      industryType: industryType ?? this.industryType,
      teamCode: teamCode ?? this.teamCode,
      brandImagePath: brandImagePath ?? this.brandImagePath,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      photoNum: photoNum ?? this.photoNum,
      todayUploadNum: todayUploadNum ?? this.todayUploadNum,
      todayUploadPersonNum: todayUploadPersonNum ?? this.todayUploadPersonNum,
      todaySelfUploadNum: todaySelfUploadNum ?? this.todaySelfUploadNum,
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
