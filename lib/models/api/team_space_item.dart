import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/team.dart';

class TeamSpaceItem {
  const TeamSpaceItem({
    required this.id,
    required this.spaceName,
    required this.spaceNo,
    required this.spaceLogo,
    required this.type,
  });

  final String id;
  final String spaceName;
  final String spaceNo;
  final String spaceLogo;
  final int type;

  factory TeamSpaceItem.fromJson(Map<String, dynamic> json) {
    return TeamSpaceItem(
      id: '${json['id'] ?? ''}',
      spaceName: json['spaceName'] as String? ?? '',
      spaceNo: json['spaceNo'] as String? ?? '',
      spaceLogo: json['spaceLogo'] as String? ?? '',
      type: json['type'] as int? ?? 0,
    );
  }

  Team toTeam() {
    final logo = spaceLogo.trim();
    return Team(
      id: id,
      name: spaceName,
      industryType: '',
      teamCode: spaceNo,
      brandImagePath: logo.isNotEmpty ? ApiConfig.resolveAssetUrl(logo) : null,
    );
  }
}
