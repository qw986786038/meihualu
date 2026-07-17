import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/pages/camera/WaterMarkController.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/utils/space_upload_helper.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
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
  final RxBool isUploading = false.obs;
  final RxString uploadStatusText = '正在同步到云端...'.obs;

  AuthService get _auth => Get.find<AuthService>();

  Future<PhotoSyncResult> syncCapture(
    String filePath, {
    required bool isVideo,
    String? location,
    DateTime? captureTime,
  }) async {
    final uploadPersonal = _auth.shouldSyncToPersonal;
    final syncTeams = _auth.syncEnabledTeams;
    if (!uploadPersonal && syncTeams.isEmpty) {
      return const PhotoSyncResult();
    }

    final token = _auth.accessToken.value.trim();
    if (token.isEmpty) {
      return const PhotoSyncResult();
    }

    final capturedAt = captureTime ?? DateTime.now();
    final watermarkData = _readWatermarkData();
    final locationService = Get.find<AMapLocationService>();
    final coordinates = locationService.currentCoordinateFields();
    final payload = await SpaceUploadHelper.build(
      filePath: filePath,
      watermarkData: watermarkData,
      locationService: locationService,
      captureTime: capturedAt,
    );
    final proofMark = _auth.proofMarkEnabled.value
        ? await WatermarkMetadata.verifyProofMark(filePath)
        : null;

    final totalTargets =
        (uploadPersonal && _auth.personalSpace.value?.id.isNotEmpty == true
            ? 1
            : 0) +
        syncTeams.length;
    var completedTargets = 0;

    isUploading.value = true;
    uploadStatusText.value = _buildUploadStatus(
      total: totalTargets,
      completed: completedTargets,
    );

    try {
      var personalUploaded = false;
      var teamUploaded = false;

      if (uploadPersonal) {
        final spaceId = _auth.personalSpace.value?.id;
        if (spaceId != null && spaceId.isNotEmpty) {
          uploadStatusText.value = _buildUploadStatus(
            total: totalTargets,
            completed: completedTargets,
            targetName: _auth.personalSpace.value?.name ?? '个人空间',
          );
          personalUploaded = await _uploadToSpace(
            accessToken: token,
            filePath: filePath,
            spaceId: spaceId,
            payload: payload,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            proofMark: proofMark,
          );
          completedTargets++;
          if (personalUploaded && Get.isRegistered<PersonalSpaceService>()) {
            await Get.find<PersonalSpaceService>().fetchMediaList(
              spaceId: spaceId,
              accessToken: token,
            );
          }
        }
      }

      for (final team in syncTeams) {
        uploadStatusText.value = _buildUploadStatus(
          total: totalTargets,
          completed: completedTargets,
          targetName: team.name,
        );
        if (Get.isRegistered<TeamWorkspaceService>()) {
          Get.find<TeamWorkspaceService>().ensureTeamInitialized(team, _auth);
        }
        final uploaded = await _uploadToSpace(
          accessToken: token,
          filePath: filePath,
          spaceId: team.id,
          payload: payload,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          proofMark: proofMark,
        );
        completedTargets++;
        if (!uploaded) continue;

        teamUploaded = true;
        if (Get.isRegistered<TeamWorkspaceService>()) {
          await Get.find<TeamWorkspaceService>().fetchTeamMedia(
            teamId: team.id,
            accessToken: token,
          );
        }
      }

      return PhotoSyncResult(
        personalUploaded: personalUploaded,
        teamUploaded: teamUploaded,
      );
    } finally {
      isUploading.value = false;
      uploadStatusText.value = '正在同步到云端...';
    }
  }

  String _buildUploadStatus({
    required int total,
    required int completed,
    String? targetName,
  }) {
    if (total <= 1) {
      if (targetName != null && targetName.isNotEmpty) {
        return '正在同步到 $targetName';
      }
      return '正在同步到云端...';
    }

    final index = (completed + 1).clamp(1, total);
    if (targetName != null && targetName.isNotEmpty) {
      return '正在同步到 $targetName ($index/$total)';
    }
    return '正在同步 ($index/$total)';
  }

  Future<bool> _uploadToSpace({
    required String accessToken,
    required String filePath,
    required String spaceId,
    required SpaceUploadPayload payload,
    required String latitude,
    required String longitude,
    bool? proofMark,
  }) async {
    try {
      final response = await Get.find<SpaceApiService>().uploadToSpace(
        accessToken: accessToken,
        filePath: filePath,
        spaceId: spaceId,
        exifData: payload.exifData,
        sha256Hash: payload.fileSha256Hash,
        watermarkId: payload.watermarkId,
        watermarkContent: payload.watermarkContent,
        latitude: latitude,
        longitude: longitude,
        antiFakeCode: payload.antiFakeCode,
        proofMark: proofMark,
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
