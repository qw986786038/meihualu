import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/media_by_sort_group.dart';
import 'package:watermark_camera/models/api/paged_api_response.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/models/api/space_media_list_data.dart';
import 'package:watermark_camera/models/api/space_list_data.dart';
import 'package:watermark_camera/models/api/space_upload_result.dart';
import 'package:watermark_camera/models/api/team_member_info.dart';
import 'package:watermark_camera/models/api/team_space_item.dart';
import 'package:watermark_camera/services/api_client.dart';
import 'package:watermark_camera/utils/api_date_format.dart';

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
    required String latitude,
    required String longitude,
    bool? proofMark,
  }) {
    final fields = <String, String>{
      'spaceId': spaceId,
      'exifData': exifData,
      'sha256Hash': sha256Hash,
      'watermarkId': '$watermarkId',
      'watermarkContent': watermarkContent,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (proofMark != null) {
      fields['proofMark'] = proofMark ? 'true' : 'false';
    }

    return _client.uploadAuthMultipart(
      'space/upload',
      accessToken: accessToken,
      filePath: filePath,
      fields: fields,
      dataFromJson: SpaceUploadResult.fromJson,
    );
  }

  Future<ApiResponse<SpaceBatchUploadData>> batchUploadToSpace({
    required String accessToken,
    required String spaceId,
    required List<SpaceBatchUploadItem> items,
    required String latitude,
    required String longitude,
  }) {
    return _client.uploadAuthBatchMultipart(
      'space/batchUpload',
      accessToken: accessToken,
      spaceId: spaceId,
      items: items,
      latitude: latitude,
      longitude: longitude,
      dataFromJson: SpaceBatchUploadData.fromJson,
    );
  }

  Future<ApiResponse<List<String>>> listMediaDatesByMonth({
    required String accessToken,
    required String spaceId,
    required String yearMonth,
  }) {
    return _client.postAuth(
      'media/listMediaDatesByMonth',
      accessToken: accessToken,
      body: {
        'spaceId': _parseSpaceId(spaceId),
        'yearMonth': yearMonth,
      },
      dataFromListJson: (list) =>
          list.map((item) => item.toString()).toList(growable: false),
    );
  }

  Future<ApiResponse<List<MediaBySortGroup>>> getMediaBySort({
    required String accessToken,
    required String spaceId,
    required String userId,
    int showType = 1,
    DateTime? date,
  }) {
    final body = <String, dynamic>{
      'spaceId': _parseSpaceId(spaceId),
      'userId': userId,
      'showType': showType,
    };
    if (date != null) {
      body['date'] = formatApiDate(date);
    }

    return _client.postAuth(
      'media/getMediaBySort',
      accessToken: accessToken,
      body: body,
      dataFromListJson: parseMediaBySortGroups,
    );
  }

  Future<ApiResponse<SpaceMediaListData>> searchMediaList({
    required String accessToken,
    required String spaceId,
    String? shootBeginDate,
    String? shootEndDate,
    String? shootUserId,
    String? shootPlace,
    int? watermarkId,
    int pageNum = 1,
    int pageSize = 50,
  }) {
    final body = <String, dynamic>{
      'spaceId': _parseSpaceId(spaceId),
      'pageNum': pageNum,
      'pageSize': pageSize,
    };
    if (shootBeginDate != null && shootBeginDate.isNotEmpty) {
      body['shootBeginDate'] = shootBeginDate;
    }
    if (shootEndDate != null && shootEndDate.isNotEmpty) {
      body['shootEndDate'] = shootEndDate;
    }
    if (shootUserId != null && shootUserId.isNotEmpty) {
      body['shootUserId'] = shootUserId;
    }
    if (shootPlace != null && shootPlace.isNotEmpty) {
      body['shootPlace'] = shootPlace;
    }
    if (watermarkId != null) {
      body['watermarkId'] = watermarkId;
    }

    return _client.postAuth(
      'media/getMediaList',
      accessToken: accessToken,
      body: body,
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
