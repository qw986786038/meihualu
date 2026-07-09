import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/space_media_service.dart';

class PersonalSpaceService extends GetxService {
  final RxList<PersonalAlbumPhoto> photos = <PersonalAlbumPhoto>[].obs;
  final RxBool isLoadingMedia = false.obs;

  List<PersonalAlbumPhoto> photosForSpace(String spaceId) {
    return photos
        .where((photo) => photo.personalSpaceId == spaceId)
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  Future<SpaceBatchUploadData?> batchUploadMedia({
    required String spaceId,
    required String accessToken,
    required List<String> filePaths,
    List<DateTime>? captureTimes,
  }) async {
    isLoadingMedia.value = true;
    try {
      final result = await Get.find<SpaceMediaService>().batchUploadMedia(
        spaceId: spaceId,
        accessToken: accessToken,
        filePaths: filePaths,
        captureTimes: captureTimes,
      );
      if (result != null && result.successCount > 0) {
        await fetchMediaList(spaceId: spaceId, accessToken: accessToken);
      }
      return result;
    } finally {
      isLoadingMedia.value = false;
    }
  }

  Future<bool> fetchMediaList({
    required String spaceId,
    required String accessToken,
  }) async {
    if (spaceId.isEmpty || accessToken.isEmpty) return false;

    isLoadingMedia.value = true;
    try {
      final response = await Get.find<SpaceApiService>().getMediaList(
        accessToken: accessToken,
        spaceId: spaceId,
      );
      if (!response.isSuccess || response.data == null) return false;

      photos.removeWhere((photo) => photo.personalSpaceId == spaceId);
      photos.addAll(
        response.data!.allFiles
            .where((file) => file.id.isNotEmpty)
            .map((file) => file.toPersonalAlbumPhoto(spaceId)),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoadingMedia.value = false;
    }
  }

  void addPhoto({
    required String personalSpaceId,
    required String filePath,
    required DateTime capturedAt,
    String? location,
    bool isVideo = false,
  }) {
    photos.insert(
      0,
      PersonalAlbumPhoto(
        id: 'personal_photo_${DateTime.now().microsecondsSinceEpoch}',
        personalSpaceId: personalSpaceId,
        filePath: filePath,
        capturedAt: capturedAt,
        location: location,
        isVideo: isVideo,
      ),
    );
  }

  void clearAll() {
    photos.clear();
  }
}

PersonalSpace resolvePersonalSpace(AuthService auth) {
  if (auth.personalSpace.value != null) {
    return auth.personalSpace.value!;
  }
  return const PersonalSpace(
    id: 'debug_personal',
    name: '李的空间',
    avatarText: '李',
  );
}
