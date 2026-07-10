import 'dart:async' show unawaited;

import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/media_by_sort_group.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/models/api/space_batch_upload_data.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/space_media_service.dart';
import 'package:watermark_camera/utils/media_capture_summary.dart';

class TeamPhotoFeedItem {
  const TeamPhotoFeedItem({
    required this.member,
    required this.photos,
    this.watermarkTime,
    this.watermarkAddress,
    this.latitude,
    this.longitude,
  });

  final TeamMember member;
  final List<TeamAlbumPhoto> photos;
  final String? watermarkTime;
  final String? watermarkAddress;
  final String? latitude;
  final String? longitude;

  DateTime? get lastCaptureTime {
    final parsed = MediaCaptureSummary.parseCaptureTime(watermarkTime);
    if (parsed != null) return parsed;
    if (photos.isEmpty) return null;
    return photos
        .map((photo) => photo.capturedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  TeamPhotoFeedItem mergedWith(TeamPhotoFeedItem other) {
    final combinedPhotos = [...photos, ...other.photos]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    final latest = _pickLatestItem(this, other);
    return TeamPhotoFeedItem(
      member: member,
      photos: combinedPhotos,
      watermarkTime: latest.watermarkTime,
      watermarkAddress: latest.watermarkAddress ?? watermarkAddress,
      latitude: latest.latitude ?? latitude,
      longitude: latest.longitude ?? longitude,
    );
  }

  static TeamPhotoFeedItem _pickLatestItem(
    TeamPhotoFeedItem a,
    TeamPhotoFeedItem b,
  ) {
    final timeA = a.lastCaptureTime;
    final timeB = b.lastCaptureTime;
    if (timeA == null) return b;
    if (timeB == null) return a;
    return timeA.isAfter(timeB) ? a : b;
  }
}

class TeamWorkspaceService extends GetxService {
  final RxMap<String, List<TeamMember>> _membersByTeam =
      <String, List<TeamMember>>{}.obs;
  final RxMap<String, List<MediaBySortGroup>> _mediaGroupsByTeam =
      <String, List<MediaBySortGroup>>{}.obs;
  final RxList<TeamAlbumPhoto> teamPhotos = <TeamAlbumPhoto>[].obs;
  final RxBool isLoadingMedia = false.obs;

  List<TeamMember> membersForTeam(String teamId) {
    return List<TeamMember>.from(_membersByTeam[teamId] ?? const []);
  }

  List<TeamAlbumPhoto> photosForTeam(String teamId) {
    return teamPhotos
        .where((photo) => photo.teamId == teamId)
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
  }

  List<TeamPhotoFeedItem> feedItemsForTeam(
    String teamId, {
    Set<String>? memberIds,
  }) {
    final members = {
      for (final member in membersForTeam(teamId)) member.id: member,
    };
    var groups = List<MediaBySortGroup>.from(
      _mediaGroupsByTeam[teamId] ?? const [],
    );

    if (memberIds != null && memberIds.isNotEmpty) {
      groups = groups.where((group) => memberIds.contains(group.userId)).toList();
    }

    return groups
        .map((group) {
          final member = members[group.userId] ??
              TeamMember(
                id: group.userId,
                name: group.nickName.isNotEmpty ? group.nickName : '成员',
                avatarText: group.nickName.isNotEmpty
                    ? group.nickName.substring(0, 1)
                    : '员',
                isSelf: false,
              );
          final photos = group.items
              .where((file) => file.id.isNotEmpty)
              .map((file) => file.toTeamAlbumPhoto(teamId))
              .toList();
          if (photos.isEmpty) return null;
          return TeamPhotoFeedItem(
            member: member,
            photos: photos,
            watermarkTime: group.watermarkTime,
            watermarkAddress: group.watermarkAddress,
            latitude: group.latitude,
            longitude: group.longitude,
          );
        })
        .whereType<TeamPhotoFeedItem>()
        .toList();
  }

  void ensureTeamInitialized(Team team, AuthService auth) {
    if (_isMockTeam(team.id)) {
      if (_membersByTeam.containsKey(team.id)) return;

      final selfName = auth.userName.value;
      final selfAvatar =
          selfName.isNotEmpty ? selfName.substring(0, 1) : '我';
      final self = TeamMember(
        id: 'member_self_${auth.phone.value}',
        name: selfName.isNotEmpty ? selfName : '我',
        avatarText: selfAvatar,
        isSelf: true,
        role: TeamMemberRole.owner,
      );

      _membersByTeam[team.id] = [self, ..._mockMembersForTeam(team)];
      return;
    }

    unawaited(fetchTeamMembers(teamId: team.id, auth: auth));
  }

  bool _isMockTeam(String teamId) {
    return teamId.startsWith('mock_') || teamId == 'debug_team';
  }

  Future<bool> fetchTeamMedia({
    required String teamId,
    required String accessToken,
    String? userId,
    int showType = 1,
    DateTime? date,
  }) async {
    if (_isMockTeam(teamId)) return false;
    final resolvedUserId =
        userId ?? Get.find<AuthService>().userId.value.trim();
    if (teamId.isEmpty || accessToken.isEmpty || resolvedUserId.isEmpty) {
      return false;
    }

    isLoadingMedia.value = true;
    try {
      final response = await Get.find<SpaceApiService>().getMediaBySort(
        accessToken: accessToken,
        spaceId: teamId,
        userId: resolvedUserId,
        showType: showType,
        date: date,
      );
      if (!response.isSuccess || response.data == null) return false;

      final groups = response.data!;
      _mediaGroupsByTeam[teamId] = groups;
      _syncMembersFromGroups(teamId, groups);

      teamPhotos.removeWhere((photo) => photo.teamId == teamId);
      teamPhotos.addAll(
        groups
            .expand((group) => group.items)
            .where((file) => file.id.isNotEmpty)
            .map((file) => file.toTeamAlbumPhoto(teamId)),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoadingMedia.value = false;
    }
  }

  void _syncMembersFromGroups(String teamId, List<MediaBySortGroup> groups) {
    final existing = {
      for (final member in membersForTeam(teamId)) member.id: member,
    };
    for (final group in groups) {
      if (group.userId.isEmpty || existing.containsKey(group.userId)) continue;
      existing[group.userId] = TeamMember(
        id: group.userId,
        name: group.nickName.isNotEmpty ? group.nickName : '成员',
        avatarText:
            group.nickName.isNotEmpty ? group.nickName.substring(0, 1) : '员',
        isSelf: false,
      );
    }
    _membersByTeam[teamId] = existing.values.toList();
  }

  Future<SpaceBatchUploadData?> batchUploadMedia({
    required String teamId,
    required String accessToken,
    required List<String> filePaths,
    List<DateTime>? captureTimes,
  }) async {
    isLoadingMedia.value = true;
    try {
      final result = await Get.find<SpaceMediaService>().batchUploadMedia(
        spaceId: teamId,
        accessToken: accessToken,
        filePaths: filePaths,
        captureTimes: captureTimes,
      );
      if (result != null && result.successCount > 0) {
        await fetchTeamMedia(teamId: teamId, accessToken: accessToken);
      }
      return result;
    } finally {
      isLoadingMedia.value = false;
    }
  }

  Future<bool> fetchTeamMembers({
    required String teamId,
    required AuthService auth,
  }) async {
    if (_isMockTeam(teamId)) return false;

    final token = auth.accessToken.value.trim();
    if (token.isEmpty) return false;

    try {
      final response = await Get.find<SpaceApiService>().teamMemberList(
        accessToken: token,
        spaceId: teamId,
      );
      if (!response.isSuccess) return false;

      final selfUserId = auth.userId.value;
      _membersByTeam[teamId] = response.rows
          .map((info) => info.toTeamMember(selfUserId: selfUserId))
          .toList();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<TeamMember> _mockMembersForTeam(Team team) {
    if (team.id.startsWith('mock_')) {
      return const [
        TeamMember(
          id: 'member_mock_1',
          name: '王工',
          avatarText: '王',
          isSelf: false,
        ),
        TeamMember(
          id: 'member_mock_2',
          name: '张经理',
          avatarText: '张',
          isSelf: false,
        ),
      ];
    }
    return const [];
  }

  TeamMember? selfMemberForTeam(String teamId, AuthService auth) {
    final members = membersForTeam(teamId);
    for (final member in members) {
      if (member.isSelf) return member;
    }
    return null;
  }

  void addTeamPhoto({
    required String teamId,
    required String filePath,
    required DateTime capturedAt,
    String? location,
    bool isVideo = false,
    String? memberId,
  }) {
    final auth = Get.find<AuthService>();
    final resolvedMemberId =
        memberId ?? selfMemberForTeam(teamId, auth)?.id ?? 'member_unknown';

    teamPhotos.insert(
      0,
      TeamAlbumPhoto(
        id: 'photo_${DateTime.now().microsecondsSinceEpoch}',
        teamId: teamId,
        memberId: resolvedMemberId,
        filePath: filePath,
        capturedAt: capturedAt,
        location: location,
        isVideo: isVideo,
      ),
    );
  }

  void clearAll() {
    _membersByTeam.clear();
    _mediaGroupsByTeam.clear();
    teamPhotos.clear();
  }
}
