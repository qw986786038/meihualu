import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/services/auth_service.dart';

class PersonalSpaceService extends GetxService {
  final RxList<PersonalAlbumPhoto> photos = <PersonalAlbumPhoto>[].obs;

  List<PersonalAlbumPhoto> photosForSpace(String spaceId) {
    return photos
        .where((photo) => photo.personalSpaceId == spaceId)
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
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
