import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/pages/camera/WaterMarkController.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/utils/space_upload_helper.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_data_keys.dart';

class PhotoSyncResult {
  const PhotoSyncResult({
    this.personalUploaded = false,
    this.teamUploaded = false,
  });

  final bool personalUploaded;
  final bool teamUploaded;

  bool get anySuccess => personalUploaded || teamUploaded;
}

/// 拍照后同步到个人空间或团队空间。
class PhotoSyncService extends GetxService {
  AuthService get _auth => Get.find<AuthService>();

  Future<PhotoSyncResult> syncCapture(
    String filePath, {
    required bool isVideo,
    String? location,
    DateTime? captureTime,
  }) async {
    final uploadPersonal = _auth.shouldSyncToPersonal;
    final uploadTeam = _auth.shouldSyncToTeam;
    if (!uploadPersonal && !uploadTeam) {
      return const PhotoSyncResult();
    }

    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      return const PhotoSyncResult();
    }

    final capturedAt = captureTime ?? DateTime.now();
    final watermarkData = _readWatermarkData();
    final locationService = Get.find<AMapLocationService>();
    final payload = await SpaceUploadHelper.build(
      filePath: filePath,
      watermarkData: watermarkData,
      locationService: locationService,
      captureTime: capturedAt,
    );

    var personalUploaded = false;
    var teamUploaded = false;

    if (uploadPersonal) {
      final spaceId = _auth.personalSpace.value?.id;
      if (spaceId != null && spaceId.isNotEmpty) {
        personalUploaded = await _uploadToSpace(
          accessToken: token,
          filePath: filePath,
          spaceId: spaceId,
          payload: payload,
        );
        if (personalUploaded && Get.isRegistered<PersonalSpaceService>()) {
          await Get.find<PersonalSpaceService>().fetchMediaList(
            spaceId: spaceId,
            accessToken: token,
          );
        }
      }
    }

    if (uploadTeam) {
      final team = _auth.activeTeam.value;
      if (team != null && team.id.isNotEmpty) {
        if (Get.isRegistered<TeamWorkspaceService>()) {
          Get.find<TeamWorkspaceService>().ensureTeamInitialized(team, _auth);
        }
        teamUploaded = await _uploadToSpace(
          accessToken: token,
          filePath: filePath,
          spaceId: team.id,
          payload: payload,
        );
        if (teamUploaded && Get.isRegistered<TeamWorkspaceService>()) {
          await Get.find<TeamWorkspaceService>().fetchTeamMedia(
            teamId: team.id,
            accessToken: token,
          );
        }
      }
    }

    return PhotoSyncResult(
      personalUploaded: personalUploaded,
      teamUploaded: teamUploaded,
    );
  }

  Future<bool> _uploadToSpace({
    required String accessToken,
    required String filePath,
    required String spaceId,
    required SpaceUploadPayload payload,
  }) async {
    try {
      final response = await Get.find<SpaceApiService>().uploadToSpace(
        accessToken: accessToken,
        filePath: filePath,
        spaceId: spaceId,
        exifData: payload.exifData,
        sha256Hash: payload.sha256Hash,
        watermarkId: payload.watermarkId,
        watermarkContent: payload.watermarkContent,
      );
      if (!response.isSuccess || response.data == null) return false;
      return response.data!.success;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _readWatermarkData() {
    if (!Get.isRegistered<WaterMarkController>()) {
      return createDefaultWatermarkData();
    }

    final controller = Get.find<WaterMarkController>();
    for (final item in controller.controller.items) {
      if (item.template.templateId == 'WaterMark') {
        return Map<String, dynamic>.from(item.data);
      }
    }
    return createDefaultWatermarkData();
  }
}
