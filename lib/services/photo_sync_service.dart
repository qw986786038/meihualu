import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';

class PhotoSyncResult {
  const PhotoSyncResult({
    this.personalUploaded = false,
    this.teamUploaded = false,
  });

  final bool personalUploaded;
  final bool teamUploaded;

  bool get anySuccess => personalUploaded || teamUploaded;
}

/// 拍照后同步到个人空间或团队相册（当前为本地模拟上传）。
class PhotoSyncService extends GetxService {
  AuthService get _auth => Get.find<AuthService>();

  Future<PhotoSyncResult> syncCapture(
    String filePath, {
    required bool isVideo,
    String? location,
  }) async {
    final uploadPersonal = _auth.shouldSyncToPersonal;
    final uploadTeam = _auth.shouldSyncToTeam;
    if (!uploadPersonal && !uploadTeam) {
      return const PhotoSyncResult();
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (uploadTeam && Get.isRegistered<TeamWorkspaceService>()) {
      final team = _auth.activeTeam.value;
      if (team != null) {
        Get.find<TeamWorkspaceService>().ensureTeamInitialized(team, _auth);
        Get.find<TeamWorkspaceService>().addTeamPhoto(
          teamId: team.id,
          filePath: filePath,
          capturedAt: DateTime.now(),
          location: location,
          isVideo: isVideo,
        );
      }
    }

    if (uploadPersonal && Get.isRegistered<PersonalSpaceService>()) {
      final space = _auth.personalSpace.value;
      if (space != null) {
        Get.find<PersonalSpaceService>().ensureSpaceInitialized(space);
        Get.find<PersonalSpaceService>().addPhoto(
          personalSpaceId: space.id,
          filePath: filePath,
          capturedAt: DateTime.now(),
          location: location,
          isVideo: isVideo,
        );
      }
    }

    return PhotoSyncResult(
      personalUploaded: uploadPersonal,
      teamUploaded: uploadTeam,
    );
  }
}
