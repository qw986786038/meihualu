import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/team.dart';

class SpaceListData {
  const SpaceListData({
    required this.userId,
    this.personalSpace,
    this.teamSpace = const [],
  });

  final String userId;
  final PersonalSpaceInfo? personalSpace;
  final List<TeamSpaceListItem> teamSpace;

  factory SpaceListData.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teamSpace'];
    return SpaceListData(
      userId: json['userId']?.toString() ?? '',
      personalSpace: json['personalSpace'] is Map<String, dynamic>
          ? PersonalSpaceInfo.fromJson(
              json['personalSpace'] as Map<String, dynamic>,
            )
          : null,
      teamSpace: rawTeams is List
          ? rawTeams
              .whereType<Map<String, dynamic>>()
              .map(TeamSpaceListItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class PersonalSpaceInfo {
  const PersonalSpaceInfo({
    required this.name,
    required this.spaceId,
    this.logo,
    this.photoNum = 0,
  });

  final String name;
  final String? logo;
  final int photoNum;
  final String spaceId;

  factory PersonalSpaceInfo.fromJson(Map<String, dynamic> json) {
    return PersonalSpaceInfo(
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      photoNum: json['photoNum'] as int? ?? 0,
      spaceId: json['spaceId']?.toString() ?? '',
    );
  }

  PersonalSpace toPersonalSpace({bool syncEnabled = true}) {
    final logoPath = logo?.trim();
    return PersonalSpace(
      id: spaceId,
      name: '',
      avatarText: '我',
      syncEnabled: syncEnabled,
      photoNum: photoNum,
      logo: logoPath != null && logoPath.isNotEmpty
          ? ApiConfig.resolveAssetUrl(logoPath)
          : null,
    );
  }
}

class TeamSpaceListItem {
  const TeamSpaceListItem({
    required this.name,
    required this.spaceId,
    this.logo,
    this.photoNum = 0,
    this.todayUploadNum = 0,
    this.todayUploadPersonNum = 0,
    this.todaySelfUploadNum = 0,
    this.selected = false,
  });

  final String name;
  final String? logo;
  final int photoNum;
  final int todayUploadNum;
  final int todayUploadPersonNum;
  final int todaySelfUploadNum;
  final String spaceId;
  final bool selected;

  factory TeamSpaceListItem.fromJson(Map<String, dynamic> json) {
    return TeamSpaceListItem(
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      photoNum: json['photoNum'] as int? ?? 0,
      todayUploadNum: json['todayUploadNum'] as int? ?? 0,
      todayUploadPersonNum: json['todayUploadPersonNum'] as int? ?? 0,
      todaySelfUploadNum: json['todaySelfUploadNum'] as int? ?? 0,
      spaceId: json['spaceId']?.toString() ?? '',
      selected: json['Selected'] as bool? ?? json['selected'] as bool? ?? false,
    );
  }

  Team toTeam({bool syncEnabled = true}) {
    final logoPath = logo?.trim();
    return Team(
      id: spaceId,
      name: name,
      industryType: '',
      teamCode: spaceId,
      brandImagePath: logoPath != null && logoPath.isNotEmpty
          ? ApiConfig.resolveAssetUrl(logoPath)
          : null,
      syncEnabled: syncEnabled,
      photoNum: photoNum,
      todayUploadNum: todayUploadNum,
      todayUploadPersonNum: todayUploadPersonNum,
      todaySelfUploadNum: todaySelfUploadNum,
    );
  }
}
