import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/team_album_photo.dart';

class SpaceMediaListData {
  const SpaceMediaListData({
    required this.total,
    required this.pageNum,
    required this.pageSize,
    this.groups = const [],
  });

  final int total;
  final int pageNum;
  final int pageSize;
  final List<SpaceMediaGroup> groups;

  factory SpaceMediaListData.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    return SpaceMediaListData(
      total: json['total'] as int? ?? 0,
      pageNum: json['pageNum'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      groups: rawGroups is List
          ? rawGroups
              .whereType<Map<String, dynamic>>()
              .map(SpaceMediaGroup.fromJson)
              .toList()
          : const [],
    );
  }

  List<SpaceMediaFile> get allFiles {
    return groups.expand((group) => group.files).toList();
  }
}

class SpaceMediaGroup {
  const SpaceMediaGroup({
    required this.date,
    this.files = const [],
  });

  final String date;
  final List<SpaceMediaFile> files;

  factory SpaceMediaGroup.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return SpaceMediaGroup(
      date: json['date'] as String? ?? '',
      files: rawFiles is List
          ? rawFiles
              .whereType<Map<String, dynamic>>()
              .map(SpaceMediaFile.fromJson)
              .toList()
          : const [],
    );
  }
}

class SpaceMediaFile {
  const SpaceMediaFile({
    required this.id,
    required this.spaceId,
    required this.uploadUserId,
    required this.fileName,
    required this.fileType,
    required this.createTime,
    this.ossUrl,
    this.thumbnailUrl,
    this.fileSha256,
    this.hasWatermark,
    this.watermarkId,
    this.watermarkContent,
    this.fileSize = 0,
  });

  final String id;
  final String spaceId;
  final String uploadUserId;
  final String fileName;
  final String fileType;
  final String createTime;
  final String? ossUrl;
  final String? thumbnailUrl;
  final String? fileSha256;
  final String? hasWatermark;
  final int? watermarkId;
  final Map<String, dynamic>? watermarkContent;
  final int fileSize;

  bool get isVideo => fileType.toLowerCase().contains('video');

  String get displayUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final url = ossUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return '';
  }

  String get downloadUrl {
    final url = ossUrl?.trim();
    if (url == null || url.isEmpty) return '';
    return ApiConfig.resolveAssetUrl(url);
  }

  DateTime get capturedAt => _parseDateTime(createTime) ?? DateTime.now();

  String? get location {
    final value = watermarkContent?['location'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? get watermarkTime {
    final value = watermarkContent?['time'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  factory SpaceMediaFile.fromJson(Map<String, dynamic> json) {
    final rawContent = json['watermarkContent'];
    return SpaceMediaFile(
      id: json['id']?.toString() ?? '',
      spaceId: json['spaceId']?.toString() ?? '',
      uploadUserId: json['uploadUserId']?.toString() ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      createTime: json['createTime'] as String? ?? '',
      ossUrl: json['ossUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileSha256: json['fileSha256'] as String?,
      hasWatermark: json['hasWatermark']?.toString(),
      watermarkId: json['watermarkId'] as int?,
      watermarkContent: rawContent is Map
          ? Map<String, dynamic>.from(rawContent)
          : null,
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }

  PersonalAlbumPhoto toPersonalAlbumPhoto(String personalSpaceId) {
    return PersonalAlbumPhoto(
      id: id,
      personalSpaceId: personalSpaceId,
      filePath: displayUrl,
      ossUrl: downloadUrl,
      fileName: fileName,
      capturedAt: capturedAt,
      location: location,
      isVideo: isVideo,
      watermarkTime: watermarkTime,
    );
  }

  TeamAlbumPhoto toTeamAlbumPhoto(String teamId) {
    return TeamAlbumPhoto(
      id: id,
      teamId: teamId,
      memberId: uploadUserId,
      filePath: displayUrl,
      ossUrl: downloadUrl,
      fileName: fileName,
      capturedAt: capturedAt,
      location: location,
      isVideo: isVideo,
      watermarkTemplateId: watermarkId?.toString(),
      watermarkTime: watermarkTime,
    );
  }

  static DateTime? _parseDateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }
}
