import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/api/space_media_list_data.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/utils/space_media_image.dart';
import 'package:watermark_camera/utils/space_media_viewer.dart';

class TeamMemberProfileArgs {
  const TeamMemberProfileArgs({required this.team, required this.member});

  final Team team;
  final TeamMember member;
}

class TeamMemberProfilePage extends StatefulWidget {
  const TeamMemberProfilePage({
    super.key,
    required this.team,
    required this.member,
  });

  final Team team;
  final TeamMember member;

  @override
  State<TeamMemberProfilePage> createState() => _TeamMemberProfilePageState();
}

class _TeamMemberProfilePageState extends State<TeamMemberProfilePage> {
  static const _primaryBlue = Color(0xFF1677FF);

  bool _isLoading = true;
  List<_MemberPhotoDateGroup> _groups = const [];

  Team get _team => widget.team;

  TeamMember get _member => widget.member;

  @override
  void initState() {
    super.initState();
    _loadMemberPhotos();
  }

  Future<void> _loadMemberPhotos() async {
    final token = Get.find<AuthService>().accessToken.value.trim();
    if (token.isEmpty || _team.id.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Get.find<SpaceApiService>().searchMediaList(
        accessToken: token,
        spaceId: _team.id,
        shootUserId: _member.id,
        pageNum: 1,
        pageSize: 100,
      );

      if (!mounted) return;

      if (!response.isSuccess || response.data == null) {
        setState(() {
          _groups = const [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _groups = _groupsFromMediaList(response.data!);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _groups = const [];
        _isLoading = false;
      });
    }
  }

  List<_MemberPhotoDateGroup> _groupsFromMediaList(SpaceMediaListData data) {
    final groups = <_MemberPhotoDateGroup>[];
    for (final group in data.groups) {
      final photos = group.files
          .where((file) => file.id.isNotEmpty)
          .map((file) => file.toTeamAlbumPhoto(_team.id))
          .toList();
      if (photos.isEmpty) continue;

      final date = _parseGroupDate(group.date) ??
          DateTime(
            photos.first.capturedAt.year,
            photos.first.capturedAt.month,
            photos.first.capturedAt.day,
          );
      photos.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      groups.add(_MemberPhotoDateGroup(date: date, photos: photos));
    }
    groups.sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  DateTime? _parseGroupDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final parts = trimmed.split(RegExp(r'[-/]'));
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  String _formatGroupDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month月$day日';
  }

  String _formatPhotoTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProfileTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  _MemberAvatar(text: _member.avatarText, size: 56),
                  const SizedBox(width: 12),
                  Text(
                    _member.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: const IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '全部动态',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: _primaryBlue,
                      child: SizedBox(height: 2),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _groups.isEmpty
                      ? Center(
                          child: Text(
                            '暂无照片记录',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMemberPhotos,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _groups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return _MemberPhotoDateGroupTile(
                                dateLabel: _formatGroupDate(group.date),
                                countLabel: '${group.photos.length}张',
                                photos: group.photos,
                                formatTime: _formatPhotoTime,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberPhotoDateGroup {
  const _MemberPhotoDateGroup({required this.date, required this.photos});

  final DateTime date;
  final List<TeamAlbumPhoto> photos;
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: const Color(0xFF333333),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '设置照片权限',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  '工作信用 暂无',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MemberPhotoDateGroupTile extends StatelessWidget {
  const _MemberPhotoDateGroupTile({
    required this.dateLabel,
    required this.countLabel,
    required this.photos,
    required this.formatTime,
  });

  final String dateLabel;
  final String countLabel;
  final List<TeamAlbumPhoto> photos;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                countLabel,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 4.0;
              final cellSize =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                      crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var index = 0; index < photos.length; index++)
                    SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: _MemberPhotoThumbnail(
                        photo: photos[index],
                        allPhotos: photos,
                        photoIndex: index,
                        timeLabel: formatTime(photos[index].capturedAt),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberPhotoThumbnail extends StatelessWidget {
  const _MemberPhotoThumbnail({
    required this.photo,
    required this.allPhotos,
    required this.photoIndex,
    required this.timeLabel,
  });

  final TeamAlbumPhoto photo;
  final List<TeamAlbumPhoto> allPhotos;
  final int photoIndex;
  final String timeLabel;

  Future<void> _openViewer(BuildContext context) async {
    await openSpaceMediaViewer(
      context,
      items: SpaceMediaViewerItem.fromTeamPhotos(allPhotos),
      initialIndex: photoIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = photo.filePath.isNotEmpty
        ? photo.filePath
        : (photo.ossUrl ?? '');

    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SpaceMediaThumbnail(
          url: url,
          placeholderColor: Colors.grey.shade200,
          isVideo: photo.isVideo,
          proofMark: photo.proofMark,
          videoIconSize: 28,
          bottomOverlay: Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                timeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.text, this.size = 44});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
