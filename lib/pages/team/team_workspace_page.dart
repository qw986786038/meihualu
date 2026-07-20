import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_album_photo.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/models/space_media_viewer_item.dart';
import 'package:watermark_camera/pages/team/team_member_profile_page.dart';
import 'package:watermark_camera/pages/team/team_membership_page.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/utils/media_capture_summary.dart';
import 'package:watermark_camera/utils/space_media_downloader.dart';
import 'package:watermark_camera/utils/space_media_image.dart';
import 'package:watermark_camera/utils/space_media_viewer.dart';
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
    _feedTabController.addListener(_onFeedTabChanged);
    final team = _team;
    if (team != null) {
      _workspace.ensureTeamInitialized(team, _auth);
      if (_auth.activeTeam.value?.id != team.id) {
        _auth.selectActiveTeam(team);
      } else {
        _auth.setWorkMode(WorkMode.team);
      }
      _loadTeamMedia(team.id);
    }
  }

  void _onFeedTabChanged() {
    if (_feedTabController.indexIsChanging) return;
    final team = _team;
    if (team == null) return;
    _loadTeamMedia(team.id);
  }

  int get _currentShowType => _feedTabController.index == 0 ? 1 : 2;

  Future<void> _loadTeamMedia(String teamId) async {
    if (!_auth.isLoggedIn.value) return;
    final token = _auth.accessToken.value.trim();
    if (token.isEmpty || teamId.isEmpty) return;
    await _workspace.fetchTeamMedia(
      teamId: teamId,
      accessToken: token,
      showType: _currentShowType,
      date: _selectedDate,
    );
  }

  @override
  void dispose() {
    _feedTabController.removeListener(_onFeedTabChanged);
    _feedTabController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatTodayDate(DateTime date) => formatTeamDateFilterLabel(date);

  Future<void> _openDateFilter() async {
    final team = _team;
    final picked = await showTeamDateFilterSheet(
      context,
      initialDate: _selectedDate,
      spaceId: team?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    if (team != null) {
      await _loadTeamMedia(team.id);
    }
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

  Future<void> _openDepartmentManagement() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamDepartmentManagement, extra: team);
  }

  Future<void> _openTeamInfo() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamInfo, extra: team);
  }

  Future<void> _openMemberProfile(TeamMember member) async {
    final team = _team;
    if (team == null) return;
    await context.push(
      AppPaths.teamMemberProfile,
      extra: TeamMemberProfileArgs(team: team, member: member),
    );
  }

  Future<void> _openWorkModeSwitchSheet() async {
    final team = _team;
    await showWorkModeSwitchSheet(
      context,
      currentTeam: team,
      currentWorkspace: WorkspaceContext.team,
    );
  }

  void _viewRecentPhotos() {
    final team = _team;
    if (team == null) return;
    setState(() => _selectedDate = DateTime.now());
    _loadTeamMedia(team.id);
  }

  Future<void> _openPhotoLedger() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamPhotoLedger, extra: team);
  }

  Future<void> _openTeamWatermarkTemplates() async {
    final team = _team;
    if (team == null) return;
    await context.push(AppPaths.teamWatermarkTemplates, extra: team);
  }

  Future<void> _downloadTeamPhotos() async {
    final team = _team;
    if (team == null) return;

    final photos = _workspace.photosForTeam(team.id);
    final items = photos
        .where((photo) => photo.downloadUrl.isNotEmpty)
        .map(
          (photo) => SpaceMediaDownloadItem(
            url: photo.downloadUrl,
            isVideo: photo.isVideo,
            fileName: photo.fileName,
          ),
        )
        .toList();
    if (items.isEmpty) {
      _showSnack('暂无照片可下载');
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('正在下载 ${items.length} 个文件...')),
      );

    final successCount = await SpaceMediaDownloader.downloadMany(items);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('已成功保存 $successCount 个到相册')),
      );
  }

  Future<void> _openUploadPicker() async {
    final team = _team;
    if (team == null || team.id.isEmpty || team.id == 'debug_team') {
      _showSnack('空间未就绪，请稍后重试');
      return;
    }
    await context.push<bool>(AppPaths.teamSpaceUpload, extra: team.id);
  }

  @override
  Widget build(BuildContext context) {
    final team = _team!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppPaths.camera),
        backgroundColor: _headerBlue,
        child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
      ),
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
            onViewRecentPhotosTap: _viewRecentPhotos,
            onPhotoLedgerTap: _openPhotoLedger,
            onTeamWatermarkTap: _openTeamWatermarkTemplates,
            onUploadPhotosTap: _openUploadPicker,
            onSwitchModeTap: _openWorkModeSwitchSheet,
          ),
          _TeamMembersTab(
            team: team,
            onInviteMembersTap: _openInviteMembers,
            onDepartmentManagementTap: _openDepartmentManagement,
            onMemberTap: _openMemberProfile,
          ),
          _TeamWorkbenchTab(
            onSearchPhotosTap: _openPhotoSearch,
            onUploadPhotosTap: _openUploadPicker,
            onDownloadPhotosTap: _downloadTeamPhotos,
          ),
          _TeamManageTab(
            team: team,
            onTeamInfoTap: _openTeamInfo,
            onTeamWatermarkTap: _openTeamWatermarkTemplates,
          ),
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
    required this.onViewRecentPhotosTap,
    required this.onPhotoLedgerTap,
    required this.onTeamWatermarkTap,
    required this.onUploadPhotosTap,
    required this.onSwitchModeTap,
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
  final VoidCallback onViewRecentPhotosTap;
  final VoidCallback onPhotoLedgerTap;
  final VoidCallback onTeamWatermarkTap;
  final VoidCallback onUploadPhotosTap;
  final VoidCallback onSwitchModeTap;

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
          onPhotoLedgerTap: onPhotoLedgerTap,
          onTeamWatermarkTap: onTeamWatermarkTap,
          onUploadPhotosTap: onUploadPhotosTap,
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
                        selectedMemberIds: selectedMemberIds,
                        onInviteMembersTap: onInviteMembersTap,
                        onViewRecentPhotosTap: onViewRecentPhotosTap,
                      ),
                      _TeamFeedList(
                        team: team,
                        groupByMember: true,
                        selectedMemberIds: selectedMemberIds,
                        onInviteMembersTap: onInviteMembersTap,
                        onViewRecentPhotosTap: onViewRecentPhotosTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required this.onPhotoLedgerTap,
    required this.onTeamWatermarkTap,
    required this.onUploadPhotosTap,
  });

  final Team team;
  final String dateLabel;
  final VoidCallback onDateFilterTap;
  final VoidCallback onMemberFilterTap;
  final VoidCallback onSearchPhotosTap;
  final VoidCallback onInviteMembersTap;
  final VoidCallback onSwitchModeTap;
  final VoidCallback onPhotoLedgerTap;
  final VoidCallback onTeamWatermarkTap;
  final VoidCallback onUploadPhotosTap;

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
            _WorkCircleStatsRow(team: team),
            _WorkCircleQuickActions(
              onPhotoLedgerTap: onPhotoLedgerTap,
              onTeamWatermarkTap: onTeamWatermarkTap,
              onUploadPhotosTap: onUploadPhotosTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkCircleStatsRow extends StatelessWidget {
  const _WorkCircleStatsRow({required this.team});

  final Team team;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photos = _workspace.photosForTeam(team.id);
      final members = _workspace.membersForTeam(team.id);
      final syncedCount = photos.where((photo) => photo.filePath.isNotEmpty).length;
      final totalCount = photos.length;
      final now = DateTime.now();
      final attendedToday = photos
          .where((photo) => _isSameDay(photo.capturedAt, now))
          .map((photo) => photo.memberId)
          .toSet()
          .length;
      final totalMembers = members.isEmpty ? 1 : members.length;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: _WorkCircleStatCard(
                primaryText: '已同步 $syncedCount 张',
                secondaryText: '全部照片 $totalCount 张',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WorkCircleStatCard(
                primaryText: '$attendedToday / $totalMembers 人',
                secondaryText: '考勤统计',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _WorkCircleStatCard(
                primaryText: '0 个',
                secondaryText: '分类相册',
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _WorkCircleStatCard extends StatelessWidget {
  const _WorkCircleStatCard({
    required this.primaryText,
    required this.secondaryText,
  });

  final String primaryText;
  final String secondaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondaryText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkCircleQuickActions extends StatelessWidget {
  const _WorkCircleQuickActions({
    required this.onPhotoLedgerTap,
    required this.onTeamWatermarkTap,
    required this.onUploadPhotosTap,
  });

  final VoidCallback onPhotoLedgerTap;
  final VoidCallback onTeamWatermarkTap;
  final VoidCallback onUploadPhotosTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          _WorkCircleQuickActionChip(
            label: '照片台账',
            icon: Icons.table_chart,
            iconColor: const Color(0xFF34C759),
            onTap: onPhotoLedgerTap,
          ),
          const SizedBox(width: 8),
          _WorkCircleQuickActionChip(
            label: '团队水印',
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF1677FF),
            onTap: onTeamWatermarkTap,
          ),
          const SizedBox(width: 8),
          _WorkCircleQuickActionChip(
            label: '上传照片',
            onTap: onUploadPhotosTap,
          ),
        ],
      ),
    );
  }
}

class _WorkCircleQuickActionChip extends StatelessWidget {
  const _WorkCircleQuickActionChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
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
    required this.selectedMemberIds,
    required this.onInviteMembersTap,
    required this.onViewRecentPhotosTap,
  });

  final Team team;
  final bool groupByMember;
  final Set<String> selectedMemberIds;
  final VoidCallback onInviteMembersTap;
  final VoidCallback onViewRecentPhotosTap;

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_workspace.isLoadingMedia.value &&
          _workspace.feedItemsForTeam(team.id).isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = _workspace.feedItemsForTeam(
        team.id,
        memberIds:
            selectedMemberIds.isEmpty ? null : selectedMemberIds,
      );
      if (items.isEmpty) {
        return _WorkCircleEmptyState(
          onInviteTap: onInviteMembersTap,
          onViewRecentTap: onViewRecentPhotosTap,
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
            final merged = memberItems.skip(1).fold(
              memberItems.first,
              (previous, item) => previous.mergedWith(item),
            );
            return _FeedItemCard(team: team, feedItem: merged);
          },
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FeedItemCard(team: team, feedItem: item);
        },
      );
    });
  }
}

class _WorkCircleEmptyState extends StatelessWidget {
  const _WorkCircleEmptyState({
    required this.onInviteTap,
    required this.onViewRecentTap,
  });

  final VoidCallback onInviteTap;
  final VoidCallback onViewRecentTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1677FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '今日',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '当日暂无照片',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onInviteTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1677FF),
                      side: const BorderSide(color: Color(0xFF1677FF)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '邀请同事加入',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onViewRecentTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '查看最近的照片',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({required this.team, required this.feedItem});

  final Team team;
  final TeamPhotoFeedItem feedItem;

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildLastCaptureSummary() {
    final current = Get.isRegistered<AMapLocationService>()
        ? Get.find<AMapLocationService>().latestLocation.value
        : null;
    final distance = MediaCaptureSummary.distanceMeters(
      fromLatitude: current?.latitude,
      fromLongitude: current?.longitude,
      toLatitude: MediaCaptureSummary.parseCoordinate(feedItem.latitude),
      toLongitude: MediaCaptureSummary.parseCoordinate(feedItem.longitude),
    );
    return MediaCaptureSummary.buildLastCaptureLine(
      lastCaptureTime: feedItem.lastCaptureTime,
      distanceMeters: distance,
    );
  }

  Future<void> _openMemberProfile(BuildContext context) async {
    await context.push(
      AppPaths.teamMemberProfile,
      extra: TeamMemberProfileArgs(team: team, member: feedItem.member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = feedItem.member;
    final photos = feedItem.photos;
    final firstPhoto = photos.isNotEmpty ? photos.first : null;
    final location = feedItem.watermarkAddress?.trim().isNotEmpty == true
        ? feedItem.watermarkAddress
        : firstPhoto?.location;
    final capturedAt = feedItem.lastCaptureTime ?? DateTime.now();

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
          GestureDetector(
            onTap: () => _openMemberProfile(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _MemberAvatar(text: member.avatarText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
              _buildLastCaptureSummary(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 6.0;
        final cellSize =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < count; index++)
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: GestureDetector(
                  onTap: () => openSpaceMediaViewer(
                    context,
                    items: SpaceMediaViewerItem.fromTeamPhotos(photos),
                    initialIndex: index,
                  ),
                  onLongPress: () => _downloadPhoto(context, photos[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SpaceMediaThumbnail(
                      url: photos[index].filePath,
                      placeholderColor: Colors.grey.shade200,
                      isVideo: photos[index].isVideo,
                      proofMark: photos[index].proofMark,
                      videoIconSize: 22,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _downloadPhoto(BuildContext context, TeamAlbumPhoto photo) async {
  final url = photo.downloadUrl;
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('暂无可下载的文件')),
    );
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('正在下载...')));

  final success = await SpaceMediaDownloader.downloadToGallery(
    ossUrl: url,
    isVideo: photo.isVideo,
    fileName: photo.fileName,
  );
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(success ? '已保存到相册' : '下载失败，请稍后重试')),
    );
}

class _TeamMembersTab extends StatefulWidget {
  const _TeamMembersTab({
    required this.team,
    required this.onInviteMembersTap,
    required this.onDepartmentManagementTap,
    required this.onMemberTap,
  });

  final Team team;
  final VoidCallback onInviteMembersTap;
  final VoidCallback onDepartmentManagementTap;
  final void Function(TeamMember member) onMemberTap;

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
                        Icons.account_tree_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: '部门管理',
                    trailingText: '分组管理团队',
                    onTap: widget.onDepartmentManagementTap,
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
                        onTap: () => widget.onMemberTap(member),
                      ),
                    ),
                ],
              ),
            ),
            if (_showManageBanner)
              _MembersManageBanner(
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
  });

  final String title;
  final VoidCallback onBack;

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
            const SizedBox(width: 48),
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
    required this.onClose,
  });

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
    required this.onUploadPhotosTap,
    required this.onDownloadPhotosTap,
  });

  final VoidCallback onSearchPhotosTap;
  final VoidCallback onUploadPhotosTap;
  final VoidCallback onDownloadPhotosTap;

  @override
  State<_TeamWorkbenchTab> createState() => _TeamWorkbenchTabState();
}

class _TeamWorkbenchTabState extends State<_TeamWorkbenchTab> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();

  late final List<_WorkbenchSection> _sections = [
    _WorkbenchSection(
      title: '最近使用',
      items: [
        _WorkbenchFeatureItem(
          label: '照片批量下载',
          icon: Icons.download_outlined,
          iconColor: _primaryBlue,
          onTap: widget.onDownloadPhotosTap,
        ),
      ],
    ),
    _WorkbenchSection(
      title: '照片管理',
      items: [
        _WorkbenchFeatureItem(
          label: '上传照片',
          icon: Icons.cloud_upload_outlined,
          iconColor: _primaryBlue,
          onTap: widget.onUploadPhotosTap,
        ),
        _WorkbenchFeatureItem(
          label: '照片搜索',
          icon: Icons.search,
          iconColor: _primaryBlue,
          onTap: widget.onSearchPhotosTap,
        ),
        _WorkbenchFeatureItem(
          label: '照片批量下载',
          icon: Icons.download_outlined,
          iconColor: _primaryBlue,
          onTap: widget.onDownloadPhotosTap,
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
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
}

class _WorkbenchTabHeader extends StatelessWidget {
  const _WorkbenchTabHeader({
    required this.onBack,
  });

  final VoidCallback onBack;

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
              const SizedBox(width: 48),
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
    final crossAxisCount = 4;

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
              childAspectRatio: crossAxisCount == 3 ? 0.82 : 0.72,
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
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 24,
              color: item.iconColor,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamManageTab extends StatefulWidget {
  const _TeamManageTab({
    required this.team,
    required this.onTeamInfoTap,
    required this.onTeamWatermarkTap,
  });

  final Team team;
  final Future<void> Function() onTeamInfoTap;
  final VoidCallback onTeamWatermarkTap;

  @override
  State<_TeamManageTab> createState() => _TeamManageTabState();
}

class _TeamManageTabState extends State<_TeamManageTab> {
  bool _photoResyncNotify = false;

  Team get _team => widget.team;

  Future<void> _copyTeamCode() async {
    await Clipboard.setData(ClipboardData(text: _team.teamCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('团队号已复制')),
    );
  }

  Future<void> _openTeamMembership() async {
    final auth = Get.find<AuthService>();
    final workspace = Get.find<TeamWorkspaceService>();
    await workspace.fetchTeamMembers(teamId: _team.id, auth: auth);
    if (!mounted) return;

    final self = workspace.selfMemberForTeam(_team.id, auth);
    final isAdmin = self?.role == TeamMemberRole.owner;
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('仅管理员可开通团队VIP')),
      );
      return;
    }

    context.push(
      AppPaths.teamMembership,
      extra: TeamMembershipArgs(team: _team),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F6F8),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          _ManageTeamHeader(
            team: _team,
            onCopyTeamCode: _copyTeamCode,
            onTeamInfoTap: widget.onTeamInfoTap,
          ),
          const SizedBox(height: 12),
          _ManageSettingsCard(
            items: [
              _ManageSettingItem(
                title: '团队会员',
                subtitle: '开通团队VIP解锁更多权益',
                onTap: _openTeamMembership,
              ),
              _ManageSettingItem(
                title: '团队水印',
                subtitle: '一人设置 团队共用',
                onTap: widget.onTeamWatermarkTap,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ManageSettingsCard(
            items: [
              _ManageSettingItem(
                title: '照片重新同步打扰',
                trailing: Switch.adaptive(
                  value: _photoResyncNotify,
                  activeTrackColor: const Color(0xFF34C759),
                  onChanged: (value) => setState(() => _photoResyncNotify = value),
                ),
                showChevron: false,
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManageTeamHeader extends StatelessWidget {
  const _ManageTeamHeader({
    required this.team,
    required this.onCopyTeamCode,
    required this.onTeamInfoTap,
  });

  final Team team;
  final VoidCallback onCopyTeamCode;
  final Future<void> Function() onTeamInfoTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTeamInfoTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ManageTeamBrand(team: team),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '团队号: ${team.teamCode}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onCopyTeamCode,
                            child: const Text(
                              '复制',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1677FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onTeamInfoTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2, size: 22, color: Colors.grey.shade700),
                        Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageTeamBrand extends StatelessWidget {
  const _ManageTeamBrand({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final brandPath = team.brandImagePath;
    if (brandPath != null && brandPath.isNotEmpty) {
      final file = File(brandPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        team.name.isNotEmpty ? team.name.substring(0, 1) : '团',
        style: const TextStyle(
          color: Color(0xFF1677FF),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ManageSettingItem {
  const _ManageSettingItem({
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool showDivider;
}

class _ManageSettingsCard extends StatelessWidget {
  const _ManageSettingsCard({required this.items});

  final List<_ManageSettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _ManageSettingTile(
              item: items[i],
              showDivider: items[i].showDivider && i < items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ManageSettingTile extends StatelessWidget {
  const _ManageSettingTile({
    required this.item,
    required this.showDivider,
  });

  final _ManageSettingItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111111),
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.trailing != null)
            item.trailing!
          else if (item.showChevron)
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );

    return Column(
      children: [
        if (item.onTap != null)
          InkWell(onTap: item.onTap, child: content)
        else
          content,
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
      ],
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
