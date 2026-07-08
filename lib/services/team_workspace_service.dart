import 'dart:async' show unawaited;

import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';

class TeamPhotoFeedItem {
  const TeamPhotoFeedItem({
    required this.member,
    required this.photos,
  });

  final TeamMember member;
  final List<TeamAlbumPhoto> photos;
}

class TeamWorkspaceService extends GetxService {
  final RxMap<String, List<TeamMember>> _membersByTeam =
      <String, List<TeamMember>>{}.obs;
  final RxList<TeamAlbumPhoto> teamPhotos = <TeamAlbumPhoto>[].obs;

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
    DateTime? onDate,
    Set<String>? memberIds,
  }) {
    final members = {
      for (final member in membersForTeam(teamId)) member.id: member,
    };
    final grouped = <String, List<TeamAlbumPhoto>>{};

    var photos = photosForTeam(teamId);
    if (onDate != null) {
      photos = photos
          .where((photo) => _isSameDay(photo.capturedAt, onDate))
          .toList();
    }
    if (memberIds != null && memberIds.isNotEmpty) {
      photos = photos
          .where((photo) => memberIds.contains(photo.memberId))
          .toList();
    }

    for (final photo in photos) {
      grouped.putIfAbsent(photo.memberId, () => []).add(photo);
    }

    return grouped.entries
        .map((entry) {
          final member = members[entry.key];
          if (member == null) return null;
          return TeamPhotoFeedItem(member: member, photos: entry.value);
        })
        .whereType<TeamPhotoFeedItem>()
        .toList()
      ..sort((a, b) {
        final aTime = a.photos.first.capturedAt;
        final bTime = b.photos.first.capturedAt;
        return bTime.compareTo(aTime);
      });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    teamPhotos.clear();
  }
}
