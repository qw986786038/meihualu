import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/paged_api_response.dart';
import 'package:watermark_camera/models/api/team_member_info.dart';
import 'package:watermark_camera/models/api/team_space_item.dart';
import 'package:watermark_camera/services/api_client.dart';

class SpaceApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<void>> createTeamSpace({
    required String accessToken,
    required String name,
    required String logo,
  }) {
    return _client.postAuth<void>(
      'space/createTeamSpace',
      accessToken: accessToken,
      body: {
        'name': name,
        'logo': logo,
      },
    );
  }

  Future<PagedApiResponse<TeamSpaceItem>> queryTeamList({
    required String accessToken,
    String spaceName = '',
    String spaceNo = '',
  }) {
    return _client.postAuthPaged(
      'space/queryTeamList',
      accessToken: accessToken,
      body: {
        'spaceName': spaceName,
        'spaceNo': spaceNo,
      },
      itemFromJson: TeamSpaceItem.fromJson,
    );
  }

  Future<ApiResponse<void>> addTeamMember({
    required String accessToken,
    required String spaceId,
  }) {
    return _client.postAuth<void>(
      'space/addTeamMember',
      accessToken: accessToken,
      body: {
        'spaceId': _parseSpaceId(spaceId),
      },
    );
  }

  Future<PagedApiResponse<TeamMemberInfo>> teamMemberList({
    required String accessToken,
    required String spaceId,
  }) {
    return _client.postAuthPaged(
      'space/teamMemberList',
      accessToken: accessToken,
      body: {
        'spaceId': _parseSpaceId(spaceId),
      },
      itemFromJson: TeamMemberInfo.fromJson,
    );
  }

  dynamic _parseSpaceId(String spaceId) {
    final value = spaceId.trim();
    return int.tryParse(value) ?? value;
  }
}
