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
import 'package:watermark_camera/widgets/work_mode_switch_sheet.dart';

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
      _auth.setWorkMode(WorkMode.team);
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

  Future<void> _openInviteMembers() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamInviteMembers, extra: team);
  }

  Future<void> _openWorkModeSwitchSheet() async {
    final team = _team;
    await showWorkModeSwitchSheet(
      context,
      currentTeam: team,
      currentWorkspace: WorkspaceContext.team,
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = _team!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButton: _bottomNavIndex <= 2
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
            onInviteMembersTap: _openInviteMembers,
            onSwitchModeTap: _openWorkModeSwitchSheet,
            onComingSoon: _showComingSoon,
          ),
          _TeamMembersTab(
            team: team,
            onInviteMembersTap: _openInviteMembers,
            onComingSoon: _showComingSoon,
          ),
          _TeamWorkbenchTab(
            onSearchPhotosTap: _openPhotoSearch,
            onComingSoon: _showComingSoon,
          ),
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
            icon: Badge(
              label: Text('1', style: TextStyle(fontSize: 10)),
              child: Icon(Icons.dashboard_outlined),
            ),
            activeIcon: Badge(
              label: Text('1', style: TextStyle(fontSize: 10)),
              child: Icon(Icons.dashboard),
            ),
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
    required this.onInviteMembersTap,
    required this.onSwitchModeTap,
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
  final VoidCallback onInviteMembersTap;
  final VoidCallback onSwitchModeTap;
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
          onInviteMembersTap: onInviteMembersTap,
          onSwitchModeTap: onSwitchModeTap,
          onComingSoon: onComingSoon,
        ),
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
        _InviteBanner(onTap: onInviteMembersTap),
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
    required this.onInviteMembersTap,
    required this.onSwitchModeTap,
    required this.onComingSoon,
  });

  final Team team;
  final String dateLabel;
  final VoidCallback onDateFilterTap;
  final VoidCallback onMemberFilterTap;
  final VoidCallback onSearchPhotosTap;
  final VoidCallback onInviteMembersTap;
  final VoidCallback onSwitchModeTap;
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
                      onTap: onSwitchModeTap,
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
                    onPressed: onInviteMembersTap,
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

class _TeamMembersTab extends StatefulWidget {
  const _TeamMembersTab({
    required this.team,
    required this.onInviteMembersTap,
    required this.onComingSoon,
  });

  final Team team;
  final VoidCallback onInviteMembersTap;
  final void Function(String feature) onComingSoon;

  @override
  State<_TeamMembersTab> createState() => _TeamMembersTabState();
}

class _TeamMembersTabState extends State<_TeamMembersTab> {
  static const _actionGreen = Color(0xFF34C759);

  final _searchController = TextEditingController();
  bool _showManageBanner = true;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  Team get _team => widget.team;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamMember> _filterMembers(List<TeamMember> members) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return members;
    return members
        .where((member) => member.name.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final members = _filterMembers(_workspace.membersForTeam(_team.id));
      final totalCount = _workspace.membersForTeam(_team.id).length;

      return ColoredBox(
        color: Colors.white,
        child: Column(
          children: [
            _MembersTabHeader(
              title: '${_team.name} ($totalCount人)',
              onBack: () => context.pop(),
              onManageTap: () => widget.onComingSoon('成员管理'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: '搜索成员',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  _MembersActionTile(
                    icon: _ActionIcon(
                      color: _actionGreen,
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: '邀请同事加入',
                    onTap: widget.onInviteMembersTap,
                  ),
                  _membersDivider(),
                  _MembersActionTile(
                    icon: _ActionIcon(
                      color: _actionGreen,
                      child: const Icon(
                        Icons.person_search_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: '成员加入申请',
                    onTap: () => widget.onComingSoon('成员加入申请'),
                  ),
                  _membersDivider(),
                  _MembersActionTile(
                    icon: _ActionIcon(
                      color: _actionGreen,
                      child: const Icon(
                        Icons.account_tree_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: '部门管理',
                    trailingText: '分组管理团队',
                    onTap: () => widget.onComingSoon('部门管理'),
                  ),
                  Divider(height: 8, thickness: 8, color: Colors.grey.shade100),
                  if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          '暂无成员',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    ...members.map(
                      (member) => _MemberListTile(
                        member: member,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('成员详情功能开发中，敬请期待')),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (_showManageBanner)
              _MembersManageBanner(
                onLearnMore: () => widget.onComingSoon('电脑后台成员管理'),
                onClose: () => setState(() => _showManageBanner = false),
              ),
          ],
        ),
      );
    });
  }

  Widget _membersDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: Colors.grey.shade200,
    );
  }
}

class _MembersTabHeader extends StatelessWidget {
  const _MembersTabHeader({
    required this.title,
    required this.onBack,
    required this.onManageTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: const Color(0xFF333333),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            TextButton(
              onPressed: onManageTap,
              child: const Text(
                '管理',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1677FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersActionTile extends StatelessWidget {
  const _MembersActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 2),
            ],
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _MemberListTile extends StatelessWidget {
  const _MemberListTile({required this.member, required this.onTap});

  final TeamMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            _MemberAvatar(text: member.avatarText, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111111),
                    ),
                  ),
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
            ),
            Text(
              member.roleLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersManageBanner extends StatelessWidget {
  const _MembersManageBanner({
    required this.onLearnMore,
    required this.onClose,
  });

  final VoidCallback onLearnMore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4FF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '成员管理，用电脑后台更方便',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            TextButton(
              onPressed: onLearnMore,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1677FF),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('了解详情', style: TextStyle(fontSize: 13)),
            ),
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamWorkbenchTab extends StatefulWidget {
  const _TeamWorkbenchTab({
    required this.onSearchPhotosTap,
    required this.onComingSoon,
  });

  final VoidCallback onSearchPhotosTap;
  final void Function(String feature) onComingSoon;

  @override
  State<_TeamWorkbenchTab> createState() => _TeamWorkbenchTabState();
}

class _TeamWorkbenchTabState extends State<_TeamWorkbenchTab> {
  static const _primaryBlue = Color(0xFF1677FF);
  static const _attendanceYellow = Color(0xFFFFB020);

  final _searchController = TextEditingController();

  late final List<_WorkbenchSection> _sections = [
    _WorkbenchSection(
      title: '最近使用',
      items: [
        _WorkbenchFeatureItem(
          label: '照片批量下载',
          icon: Icons.download_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('照片批量下载'),
        ),
      ],
    ),
    _WorkbenchSection(
      title: '照片管理',
      items: [
        _WorkbenchFeatureItem(
          label: '全部照片',
          icon: Icons.photo_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('全部照片'),
        ),
        _WorkbenchFeatureItem(
          label: '上传照片',
          icon: Icons.cloud_upload_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('上传照片'),
        ),
        _WorkbenchFeatureItem(
          label: '照片搜索',
          icon: Icons.search,
          iconColor: _primaryBlue,
          onTap: widget.onSearchPhotosTap,
        ),
        _WorkbenchFeatureItem(
          label: '分类相册',
          icon: Icons.folder_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('分类相册'),
        ),
        _WorkbenchFeatureItem(
          label: '照片台账表',
          icon: Icons.table_chart_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('照片台账表'),
        ),
        _WorkbenchFeatureItem(
          label: '照片批量下载',
          icon: Icons.download_outlined,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('照片批量下载'),
        ),
        _WorkbenchFeatureItem(
          label: '照片查看码',
          icon: Icons.qr_code_2,
          iconColor: _primaryBlue,
          onTap: () => widget.onComingSoon('照片查看码'),
        ),
        _WorkbenchFeatureItem(
          label: '分类相册旧版',
          icon: Icons.folder_off_outlined,
          iconColor: Colors.grey,
          disabled: true,
          onTap: () => widget.onComingSoon('分类相册旧版'),
        ),
      ],
    ),
    _WorkbenchSection(
      title: '考勤管理',
      items: [
        _WorkbenchFeatureItem(
          label: '考勤统计',
          icon: Icons.calendar_month_outlined,
          iconColor: _attendanceYellow,
          onTap: () => widget.onComingSoon('考勤统计'),
        ),
        _WorkbenchFeatureItem(
          label: '请假',
          icon: Icons.event_busy_outlined,
          iconColor: _attendanceYellow,
          onTap: () => widget.onComingSoon('请假'),
        ),
        _WorkbenchFeatureItem(
          label: '审批',
          icon: Icons.approval_outlined,
          iconColor: _attendanceYellow,
          onTap: () => widget.onComingSoon('审批'),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_WorkbenchSection> get _visibleSections {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _sections;

    return _sections
        .map((section) {
          final items = section.items
              .where((item) => item.label.contains(query))
              .toList();
          if (items.isEmpty) return null;
          return _WorkbenchSection(title: section.title, items: items);
        })
        .whereType<_WorkbenchSection>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections;

    return ColoredBox(
      color: const Color(0xFFF5F6F8),
      child: Column(
        children: [
          _WorkbenchTabHeader(
            onBack: () => context.pop(),
            onContactService: () => widget.onComingSoon('联系客服'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '搜功能',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        '未找到相关功能',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  ...sections.map(
                    (section) => _WorkbenchSectionCard(section: section),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchSection {
  const _WorkbenchSection({required this.title, required this.items});

  final String title;
  final List<_WorkbenchFeatureItem> items;
}

class _WorkbenchFeatureItem {
  const _WorkbenchFeatureItem({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.disabled = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool disabled;
}

class _WorkbenchTabHeader extends StatelessWidget {
  const _WorkbenchTabHeader({
    required this.onBack,
    required this.onContactService,
  });

  final VoidCallback onBack;
  final VoidCallback onContactService;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: const Color(0xFF333333),
              ),
              const Expanded(
                child: Text(
                  '工作台',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              TextButton(
                onPressed: onContactService,
                child: const Text(
                  '联系客服',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1677FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkbenchSectionCard extends StatelessWidget {
  const _WorkbenchSectionCard({required this.section});

  final _WorkbenchSection section;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = section.title == '考勤管理' ? 3 : 4;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 8,
              childAspectRatio: crossAxisCount == 3 ? 0.88 : 0.78,
            ),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _WorkbenchFeatureTile(item: item);
            },
          ),
        ],
      ),
    );
  }
}

class _WorkbenchFeatureTile extends StatelessWidget {
  const _WorkbenchFeatureTile({required this.item});

  final _WorkbenchFeatureItem item;

  @override
  Widget build(BuildContext context) {
    final iconBackground = item.disabled
        ? Colors.grey.shade100
        : item.iconColor.withValues(alpha: 0.12);

    return InkWell(
      onTap: item.disabled ? null : item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 26,
              color: item.disabled ? Colors.grey.shade400 : item.iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: item.disabled ? Colors.grey.shade400 : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
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
