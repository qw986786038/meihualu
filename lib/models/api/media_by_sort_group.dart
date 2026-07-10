import 'package:watermark_camera/models/api/space_media_list_data.dart';

class MediaBySortGroup {
  const MediaBySortGroup({
    this.mediaGroupId,
    required this.userId,
    required this.nickName,
    this.avatar,
    this.watermarkTime,
    this.watermarkAddress,
    this.latitude,
    this.longitude,
    this.items = const [],
    this.photoCount = 0,
    this.workDuration,
    this.workTimeRange,
  });

  final String? mediaGroupId;
  final String userId;
  final String nickName;
  final String? avatar;
  final String? watermarkTime;
  final String? watermarkAddress;
  final String? latitude;
  final String? longitude;
  final List<SpaceMediaFile> items;
  final int photoCount;
  final String? workDuration;
  final String? workTimeRange;

  factory MediaBySortGroup.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MediaBySortGroup(
      mediaGroupId: json['mediaGroupId']?.toString(),
      userId: json['userId']?.toString() ?? '',
      nickName: json['nickName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      watermarkTime: json['watermarkTime'] as String?,
      watermarkAddress: json['watermarkAddress'] as String?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SpaceMediaFile.fromJson)
              .toList()
          : const [],
      photoCount: json['photoCount'] as int? ?? 0,
      workDuration: json['workDuration'] as String?,
      workTimeRange: json['workTimeRange'] as String?,
    );
  }

  List<SpaceMediaFile> get allFiles => items;
}

List<MediaBySortGroup> parseMediaBySortGroups(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(MediaBySortGroup.fromJson)
      .toList();
}
