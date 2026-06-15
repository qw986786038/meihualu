import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';

Future<void> showWorkModeSwitchSheet(
  BuildContext context, {
  Team? currentTeam,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: WorkModeSwitchSheet(currentTeam: currentTeam),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

class WorkModeSwitchSheet extends StatelessWidget {
  const WorkModeSwitchSheet({super.key, this.currentTeam});

  final Team? currentTeam;

  AuthService get _auth => Get.find<AuthService>();
  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();
  PersonalSpaceService get _personalService => Get.find<PersonalSpaceService>();

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  void _close(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _openCreateTeam(BuildContext context) async {
    _close(context);
    await context.push(AppPaths.createTeam);
  }

  Future<void> _openJoinTeam(BuildContext context) async {
    _close(context);
    await context.push(AppPaths.joinTeam);
  }

  void _selectTeam(BuildContext context, Team team) {
    _auth.activeTeam.value = team;
    _auth.setWorkMode(WorkMode.team);
    _workspace.ensureTeamInitialized(team, _auth);
    _close(context);

    final currentPath = GoRouterState.of(context).uri.path;
    final isSameTeamWorkspace =
        currentPath == AppPaths.teamWorkspace &&
        (_auth.activeTeam.value?.id ?? team.id) == team.id;
    if (isSameTeamWorkspace) return;

    context.push(AppPaths.teamWorkspace, extra: team.id);
  }

  void _selectPersonal(BuildContext context) {
    _auth.setWorkMode(WorkMode.personal);
    _close(context);

    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == AppPaths.personalSpace) return;

    context.push(AppPaths.personalSpace);
  }

  String _teamSubtitle(Team team) {
    final photos = _workspace.photosForTeam(team.id);
    final now = DateTime.now();
    final todayPhotos = photos.where((photo) => _isSameDay(photo.capturedAt, now));
    final todayMemberCount =
        todayPhotos.map((photo) => photo.memberId).toSet().length;
    return '今天$todayMemberCount人已拍照，共${photos.length}张';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  PersonalSpace? get _personalSpace {
    if (_auth.personalSpace.value != null) {
      return _auth.personalSpace.value;
    }
    if (!_auth.isLoggedIn.value) {
      return const PersonalSpace(
        id: 'debug_personal',
        name: '李的空间',
        avatarText: '李',
      );
    }
    return null;
  }

  bool _isTeamSelected(Team team) {
    if (_isPersonalSelected) return false;
    final activeId = _auth.activeTeam.value?.id ?? currentTeam?.id;
    return activeId == team.id;
  }

  bool get _isPersonalSelected => _auth.workMode.value == WorkMode.personal;

  int _personalPhotoCount() {
    final space = _personalSpace;
    if (space == null) return 0;
    _personalService.ensureSpaceInitialized(space);
    return _personalService.photosForSpace(space.id).length;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, topInset > 0 ? 8 : 16, 16, 20),
          child: Obx(() {
            final teams = _auth.teams.isNotEmpty
                ? _auth.teams
                : currentTeam != null
                    ? [currentTeam!]
                    : <Team>[];
            final personalSpace = _personalSpace;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GradientActionButton(
                        colors: const [Color(0xFFFF7A45), Color(0xFFE64545)],
                        icon: Icons.add,
                        label: '创建团队',
                        onTap: () => _openCreateTeam(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GradientActionButton(
                        colors: const [Color(0xFF3D8BFF), Color(0xFF1677FF)],
                        icon: Icons.search,
                        label: '加入团队',
                        onTap: () => _openJoinTeam(context),
                      ),
                    ),
                  ],
                ),
                if (teams.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '我的团队',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...teams.map(
                    (team) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WorkspaceCard(
                        leading: _TeamBrandBadge(team: team, showBadge: true),
                        title: team.name,
                        subtitle: _teamSubtitle(team),
                        selected: _isTeamSelected(team),
                        onTap: () => _selectTeam(context, team),
                      ),
                    ),
                  ),
                ],
                if (personalSpace != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '个人空间',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WorkspaceCard(
                    leading: _AvatarBadge(text: personalSpace.avatarText),
                    title: personalSpace.name,
                    subtitle: '共${_personalPhotoCount()}张',
                    tag: '仅自己可见',
                    selected: _isPersonalSelected,
                    onTap: () => _selectPersonal(context),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showComingSoon(context, '切换列表样式'),
                    icon: Icon(Icons.view_list_outlined, size: 18, color: Colors.grey.shade500),
                    label: Text(
                      '切换列表样式',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<Color> colors;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.tag,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String? tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Color(0xFF1677FF), size: 22)
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TeamBrandBadge extends StatelessWidget {
  const _TeamBrandBadge({required this.team, this.showBadge = false});

  final Team team;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    Widget badge = _buildBadgeContent();

    if (showBadge) {
      badge = Badge(
        label: const Text('1', style: TextStyle(fontSize: 10)),
        backgroundColor: const Color(0xFFE64545),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildBadgeContent() {
    final brandPath = team.brandImagePath;
    if (brandPath != null && brandPath.isNotEmpty) {
      final file = File(brandPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: 44,
      height: 44,
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
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
