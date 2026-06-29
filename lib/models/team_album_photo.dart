class TeamAlbumPhoto {
  const TeamAlbumPhoto({
    required this.id,
    required this.teamId,
    required this.memberId,
    required this.filePath,
    required this.capturedAt,
    this.location,
    this.isVideo = false,
    this.watermarkTemplateId,
  });

  final String id;
  final String teamId;
  final String memberId;
  final String filePath;
  final DateTime capturedAt;
  final String? location;
  final bool isVideo;
  final String? watermarkTemplateId;
}
