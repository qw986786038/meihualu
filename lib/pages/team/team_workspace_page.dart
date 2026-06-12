import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/widgets/team_date_filter_sheet.dart';
import 'package:watermark_camera/widgets/team_member_filter_sheet.dart';

class TeamWorkspacePage extends StatefulWidget {
  const TeamWorkspacePage({super.key, this.teamId});

  final String? teamId;

  /// 调试预览用，无团队数据时展示工作圈 UI。
  static const debugTeam = Team(
    id: 'debug_team',
    name: '科技公司',
    industryType: '房屋建筑业',
    teamCode: '000000',
  );

  @override
  State<TeamWorkspacePage> createState() => _TeamWorkspacePageState();
}

class _TeamWorkspacePageState extends State<TeamWorkspacePage>
    with SingleTickerProviderStateMixin {
  static const _headerBlue = Color(0xFF1677FF);

  late final TabController _feedTabController;
  int _bottomNavIndex = 0;
  DateTime _selectedDate = DateTime.now();
  Set<String> _selectedMemberIds = {};

  AuthService get _auth => Get.find<AuthService>();
  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  Team? get _team {
    final teamId = widget.teamId ?? _auth.activeTeam.value?.id;
    if (teamId != null) {
      for (final team in _auth.teams) {
        if (team.id == teamId) return team;
      }
    }
    return _auth.activeTeam.value ?? TeamWorkspacePage.debugTeam;
  }

  @override
  void initState() {
    super.initState();
    _feedTabController = TabController(length: 2, vsync: this);
    final team = _team;
    if (team != null) {
      _workspace.ensureTeamInitialized(team, _auth);
      if (_auth.activeTeam.value == null) {
        _auth.activeTeam.value = team;
      }
    }
  }

  @override
  void dispose() {
    _feedTabController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  String _formatTodayDate(DateTime date) => formatTeamDateFilterLabel(date);

  Future<void> _openDateFilter() async {
    final picked = await showTeamDateFilterSheet(
      context,
      initialDate: _selectedDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _openMemberFilter() async {
    final team = _team;
    if (team == null) return;

    final result = await showTeamMemberFilterSheet(
      context,
      teamId: team.id,
      initialSelectedMemberIds: _selectedMemberIds,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedMemberIds = result.memberIds);
  }

  Future<void> _openPhotoSearch() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamPhotoSearch, extra: team.id);
  }

  @override
  Widget build(BuildContext context) {
    final team = _team!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButton: _bottomNavIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push(AppPaths.camera),
              backgroundColor: _headerBlue,
              child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
            )
          : null,
      body: IndexedStack(
        index: _bottomNavIndex,
        children: [
          _WorkCircleTab(
            team: team,
            feedTabController: _feedTabController,
            dateLabel: _formatTodayDate(_selectedDate),
            selectedDate: _selectedDate,
            selectedMemberIds: _selectedMemberIds,
            onDateFilterTap: _openDateFilter,
            onMemberFilterTap: _openMemberFilter,
            onSearchPhotosTap: _openPhotoSearch,
            onComingSoon: _showComingSoon,
          ),
          _TeamMembersTab(team: team),
          _PlaceholderTab(title: '工作台'),
          _PlaceholderTab(title: '管理'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _headerBlue,
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '工作圈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: '团队成员',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: '工作台',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '管理',
          ),
        ],
      ),
    );
  }
}

class _WorkCircleTab extends StatelessWidget {
  const _WorkCircleTab({
    required this.team,
    required this.feedTabController,
    required this.dateLabel,
    required this.selectedDate,
    required this.selectedMemberIds,
    required this.onDateFilterTap,
    required this.onMemberFilterTap,
    required this.onSearchPhotosTap,
    required this.onComingSoon,
  });

  final Team team;
  final TabController feedTabController;
  final String dateLabel;
  final DateTime selectedDate;
  final Set<String> selectedMemberIds;
  final VoidCallback onDateFilterTap;
  final VoidCallback onMemberFilterTap;
  final VoidCallback onSearchPhotosTap;
  final void Function(String feature) onComingSoon;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();
  AuthService get _auth => Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TeamHeader(
          team: team,
          dateLabel: dateLabel,
          onDateFilterTap: onDateFilterTap,
          onMemberFilterTap: onMemberFilterTap,
          onSearchPhotosTap: onSearchPhotosTap,
          onComingSoon: onComingSoon,),
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  controller: feedTabController,
                  labelColor: const Color(0xFF1677FF),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF1677FF),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: '按时间'),
                    Tab(text: '按人员'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: feedTabController,
                    children: [
                      _TeamFeedList(
                        team: team,
                        groupByMember: false,
                        selectedDate: selectedDate,
                        selectedMemberIds: selectedMemberIds,
                      ),
                      _TeamFeedList(
                        team: team,
                        groupByMember: true,
                        selectedDate: selectedDate,
                        selectedMemberIds: selectedMemberIds,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Obx(() {
          final self = _workspace.selfMemberForTeam(team.id, _auth);
          if (self == null) return const SizedBox.shrink();
          return _TeamButlerMessage(
            memberName: self.name,
            teamName: team.name,
          );
        }),
        _InviteBanner(onTap: () => onComingSoon('邀请成员')),
      ],
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.team,
    required this.dateLabel,
    required this.onDateFilterTap,
    required this.onMemberFilterTap,
    required this.onSearchPhotosTap,
    required this.onComingSoon,
  });

  final Team team;
  final String dateLabel;
  final VoidCallback onDateFilterTap;
  final VoidCallback onMemberFilterTap;
  final VoidCallback onSearchPhotosTap;
  final void Function(String feature) onComingSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1677FF),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => onComingSoon('切换团队'),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              team.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.expand_more, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => onComingSoon('邀请成员'),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      '邀请成员',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _HeaderFilterChip(
                      label: dateLabel,
                      fillWidth: true,
                      onTap: onDateFilterTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _HeaderFilterChip(
                    label: '成员',
                    icon: Icons.person_outline,
                    onTap: onMemberFilterTap,
                  ),
                  const SizedBox(width: 6),
                  _HeaderFilterChip(
                    label: '搜照片',
                    icon: Icons.search,
                    showDropdownArrow: false,
                    onTap: onSearchPhotosTap,
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

class _HeaderFilterChip extends StatelessWidget {
  const _HeaderFilterChip({
    required this.label,
    this.icon,
    required this.onTap,
    this.showDropdownArrow = true,
    this.fillWidth = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool showDropdownArrow;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              if (fillWidth)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                )
              else
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              if (showDropdownArrow) ...[
                const SizedBox(width: 2),
                const Icon(Icons.expand_more, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamFeedList extends StatelessWidget {
  const _TeamFeedList({
    required this.team,
    required this.groupByMember,
    required this.selectedDate,
    required this.selectedMemberIds,
  });

  final Team team;
  final bool groupByMember;
  final DateTime selectedDate;
  final Set<String> selectedMemberIds;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = _workspace.feedItemsForTeam(
        team.id,
        onDate: selectedDate,
        memberIds:
            selectedMemberIds.isEmpty ? null : selectedMemberIds,
      );
      if (items.isEmpty) {
        return Center(
          child: Text(
            '该日期暂无团队照片\n开启团队同步后，拍照会自动上传到这里',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
          ),
        );
      }

      if (groupByMember) {
        final memberIds = items.map((item) => item.member.id).toSet().toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: memberIds.length,
          itemBuilder: (context, index) {
            final memberId = memberIds[index];
            final memberItems =
                items.where((item) => item.member.id == memberId).toList();
            final member = memberItems.first.member;
            final photos =
                memberItems.expand((item) => item.photos).toList();
            return _FeedItemCard(member: member, photos: photos);
          },
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FeedItemCard(member: item.member, photos: item.photos);
        },
      );
    });
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({
    required this.member,
    required this.photos,
  });

  final TeamMember member;
  final List<TeamAlbumPhoto> photos;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final firstPhoto = photos.isNotEmpty ? photos.first : null;
    final location = firstPhoto?.location;
    final capturedAt = firstPhoto?.capturedAt ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MemberAvatar(text: member.avatarText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showComingSoon(context, '团队水印'),
                      child: Text(
                        '非团队水印 >',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PhotoGrid(photos: photos),
          const SizedBox(height: 10),
          Text(
            '${_formatTime(capturedAt)} ${location ?? '暂无位置信息'}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '上次拍照:5分钟前, <100米 查看路线 >',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FeedAction(label: '分享', onTap: () => _showComingSoon(context, '分享')),
              _FeedAction(label: '评论', onTap: () => _showComingSoon(context, '评论')),
              _FeedAction(label: '赞', onTap: () => _showComingSoon(context, '点赞')),
              _FeedAction(label: '提整改', onTap: () => _showComingSoon(context, '提整改')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.photos});

  final List<TeamAlbumPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('暂无照片', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    final count = photos.length.clamp(1, 4);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final path = photo.filePath;
        final file = File(path);
        if (!file.existsSync()) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(file, fit: BoxFit.cover),
        );
      },
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _TeamMembersTab extends StatelessWidget {
  const _TeamMembersTab({required this.team});

  final Team team;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = _workspace.membersForTeam(team.id);
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('${team.name} · 成员'),
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
          ),
          if (members.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('暂无成员')),
            )
          else
            SliverList.separated(
              itemCount: members.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: _MemberAvatar(text: member.avatarText, size: 44),
                  title: Row(
                    children: [
                      Text(member.name),
                      if (member.isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '我',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1677FF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(member.roleLabel),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('成员详情功能开发中，敬请期待')),
                    );
                  },
                );
              },
            ),
        ],
      );
    });
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title功能开发中，敬请期待',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _InviteBanner extends StatelessWidget {
  const _InviteBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4FF),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '邀请成员，体验完整团队功能',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1677FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1677FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '去邀请',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamButlerMessage extends StatelessWidget {
  const _TeamButlerMessage({
    required this.memberName,
    required this.teamName,
  });

  final String memberName;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF1677FF), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '团队管家',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberName 已成功创建团队「$teamName」',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.text, this.size = 36});

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
