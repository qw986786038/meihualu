import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/paged_api_response.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/models/api/space_media_list_data.dart';
import 'package:watermark_camera/models/api/space_list_data.dart';
import 'package:watermark_camera/models/api/space_upload_result.dart';
import 'package:watermark_camera/models/api/team_member_info.dart';
import 'package:watermark_camera/models/api/team_space_item.dart';
import 'package:watermark_camera/services/api_client.dart';

class SpaceApiService extends GetxService {
  ApiClient get _client => Get.find<ApiClient>();

  Future<ApiResponse<SpaceListData>> getSpaceList({
    required String accessToken,
  }) {
    return _client.postAuth(
      'space/getList',
      accessToken: accessToken,
      dataFromJson: SpaceListData.fromJson,
    );
  }

  Future<ApiResponse<SpaceUploadResult>> uploadToSpace({
    required String accessToken,
    required String filePath,
    required String spaceId,
    required String exifData,
    required String sha256Hash,
    required int watermarkId,
    required String watermarkContent,
  }) {
    return _client.uploadAuthMultipart(
      'space/upload',
      accessToken: accessToken,
      filePath: filePath,
      fields: {
        'spaceId': spaceId,
        'exifData': exifData,
        'sha256Hash': sha256Hash,
        'watermarkId': '$watermarkId',
        'watermarkContent': watermarkContent,
      },
      dataFromJson: SpaceUploadResult.fromJson,
    );
  }

  Future<ApiResponse<SpaceBatchUploadData>> batchUploadToSpace({
    required String accessToken,
    required String spaceId,
    required List<SpaceBatchUploadItem> items,
  }) {
    return _client.uploadAuthBatchMultipart(
      'space/batchUpload',
      accessToken: accessToken,
      spaceId: spaceId,
      items: items,
      dataFromJson: SpaceBatchUploadData.fromJson,
    );
  }

  Future<ApiResponse<SpaceMediaListData>> getMediaList({
    required String accessToken,
    required String spaceId,
    int pageNum = 1,
    int pageSize = 50,
  }) {
    return _client.postAuth(
      'space/getMediaList',
      accessToken: accessToken,
      body: {
        'spaceId': _parseSpaceId(spaceId),
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
      dataFromJson: SpaceMediaListData.fromJson,
    );
  }

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
