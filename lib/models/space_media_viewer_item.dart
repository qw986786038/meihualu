import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/space_media_list_data.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/team_album_photo.dart';

class SpaceMediaViewerItem {
  const SpaceMediaViewerItem({
    required this.id,
    required this.previewUrl,
    required this.originalUrl,
    this.fileName,
    this.isVideo = false,
    this.location,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String previewUrl;
  final String originalUrl;
  final String? fileName;
  final bool isVideo;
  final String? location;
  final double? latitude;
  final double? longitude;

  factory SpaceMediaViewerItem.fromPersonalPhoto(PersonalAlbumPhoto photo) {
    return SpaceMediaViewerItem(
      id: photo.id,
      previewUrl: photo.filePath,
      originalUrl: _resolveOriginalUrl(
        remoteUrl: photo.ossUrl,
        previewUrl: photo.filePath,
      ),
      fileName: photo.fileName,
      isVideo: photo.isVideo,
      location: photo.location,
    );
  }

  factory SpaceMediaViewerItem.fromTeamPhoto(TeamAlbumPhoto photo) {
    return SpaceMediaViewerItem(
      id: photo.id,
      previewUrl: photo.filePath,
      originalUrl: _resolveOriginalUrl(
        remoteUrl: photo.ossUrl,
        previewUrl: photo.filePath,
      ),
      fileName: photo.fileName,
      isVideo: photo.isVideo,
      location: photo.location,
    );
  }

  factory SpaceMediaViewerItem.fromSpaceMediaFile(SpaceMediaFile file) {
    final content = file.watermarkContent;
    return SpaceMediaViewerItem(
      id: file.id,
      previewUrl: file.displayUrl,
      originalUrl: file.downloadUrl.isNotEmpty
          ? file.downloadUrl
          : file.displayUrl,
      fileName: file.fileName,
      isVideo: file.isVideo,
      location: file.location,
      latitude: _parseCoordinate(content?['latitude']),
      longitude: _parseCoordinate(content?['longitude']),
    );
  }

  static List<SpaceMediaViewerItem> fromPersonalPhotos(
    List<PersonalAlbumPhoto> photos,
  ) {
    return photos.map(SpaceMediaViewerItem.fromPersonalPhoto).toList();
  }

  static List<SpaceMediaViewerItem> fromTeamPhotos(
    List<TeamAlbumPhoto> photos,
  ) {
    return photos.map(SpaceMediaViewerItem.fromTeamPhoto).toList();
  }

  static List<SpaceMediaViewerItem> fromSpaceMediaFiles(
    List<SpaceMediaFile> files,
  ) {
    return files.map(SpaceMediaViewerItem.fromSpaceMediaFile).toList();
  }

  static String _resolveOriginalUrl({
    required String? remoteUrl,
    required String previewUrl,
  }) {
    final remote = remoteUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      return ApiConfig.resolveAssetUrl(remote);
    }
    final preview = previewUrl.trim();
    if (preview.startsWith('http://') || preview.startsWith('https://')) {
      return preview;
    }
    return preview;
  }

  static double? _parseCoordinate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
}
