import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';

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

class _TeamMemberProfilePageState extends State<TeamMemberProfilePage>
    with SingleTickerProviderStateMixin {
  static const _primaryBlue = Color(0xFF1677FF);

  late final TabController _tabController;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  Team get _team => widget.team;

  TeamMember get _member => widget.member;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  List<_MemberPhotoDateGroup> _photoGroups() {
    final photos = _workspace
        .photosForTeam(_team.id)
        .where((photo) => photo.memberId == _member.id)
        .toList()
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    final map = <String, List<TeamAlbumPhoto>>{};
    for (final photo in photos) {
      final key = _dateKey(photo.capturedAt);
      map.putIfAbsent(key, () => []).add(photo);
    }

    return map.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return _MemberPhotoDateGroup(date: date, photos: entry.value);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

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
            _ProfileTopBar(onShareTap: () => _showComingSoon('分享到微信')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ProfileActionButton(
                      label: '查看考勤',
                      onTap: () => _showComingSoon('查看考勤'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileActionButton(
                      label: '拍照路线',
                      onTap: () => _showComingSoon('拍照路线'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileActionButton(
                      label: '通话',
                      icon: const Icon(
                        Icons.phone_in_talk,
                        size: 16,
                        color: Color(0xFF07C160),
                      ),
                      onTap: () => _showComingSoon('通话'),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: _primaryBlue,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: _primaryBlue,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: '全部动态'),
                Tab(text: '拼图汇报'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Obx(() {
                    final groups = _photoGroups();
                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          '暂无动态',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return _MemberPhotoDateGroupTile(
                          dateLabel: _formatGroupDate(group.date),
                          countLabel: '${group.photos.length}张',
                          photos: group.photos,
                          formatTime: _formatPhotoTime,
                          onDetailTap: () => _showComingSoon('动态详情'),
                        );
                      },
                    );
                  }),
                  Center(
                    child: Text(
                      '暂无拼图汇报',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
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
  const _ProfileTopBar({required this.onShareTap});

  final VoidCallback onShareTap;

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
                Icon(Icons.verified_user_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  '工作信用 暂无',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onShareTap,
            child: const Text(
              '分享到微信',
              style: TextStyle(fontSize: 14, color: Color(0xFF1677FF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
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
    required this.onDetailTap,
  });

  final String dateLabel;
  final String countLabel;
  final List<TeamAlbumPhoto> photos;
  final String Function(DateTime) formatTime;
  final VoidCallback onDetailTap;

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
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onDetailTap,
                child: const Text(
                  '详情 >',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1677FF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _MemberPhotoThumbnail(
                photo: photo,
                timeLabel: formatTime(photo.capturedAt),
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
    required this.timeLabel,
  });

  final TeamAlbumPhoto photo;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.filePath);
    final hasImage = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.file(file, fit: BoxFit.cover)
          else
            Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(
                photo.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                color: Colors.grey.shade500,
                size: 28,
              ),
            ),
          if (photo.isVideo)
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          Positioned(
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
        ],
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
