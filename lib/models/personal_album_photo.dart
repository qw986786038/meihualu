class PersonalAlbumPhoto {
  const PersonalAlbumPhoto({
    required this.id,
    required this.personalSpaceId,
    required this.filePath,
    required this.capturedAt,
    this.location,
    this.isVideo = false,
  });

  final String id;
  final String personalSpaceId;
  final String filePath;
  final DateTime capturedAt;
  final String? location;
  final bool isVideo;
}
