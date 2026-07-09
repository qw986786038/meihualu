class TeamAlbumPhoto {
  const TeamAlbumPhoto({
    required this.id,
    required this.teamId,
    required this.memberId,
    required this.filePath,
    required this.capturedAt,
    this.ossUrl,
    this.fileName,
    this.location,
    this.isVideo = false,
    this.watermarkTemplateId,
    this.watermarkTime,
  });

  final String id;
  final String teamId;
  final String memberId;
  final String filePath;
  final String? ossUrl;
  final String? fileName;
  final DateTime capturedAt;
  final String? location;
  final bool isVideo;
  final String? watermarkTemplateId;
  final String? watermarkTime;

  String get downloadUrl {
    final remote = ossUrl?.trim();
    if (remote != null && remote.isNotEmpty) return remote;
    final local = filePath.trim();
    if (local.isNotEmpty &&
        !local.startsWith('http://') &&
        !local.startsWith('https://')) {
      return local;
    }
    return '';
  }
}
