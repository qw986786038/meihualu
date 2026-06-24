import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_brand.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';

class TeamInfoPage extends StatefulWidget {
  const TeamInfoPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamInfoPage> createState() => _TeamInfoPageState();
}

class _TeamInfoPageState extends State<TeamInfoPage> {
  static const _primaryBlue = Color(0xFF1677FF);

  AuthService get _auth => Get.find<AuthService>();

  Team get _initialTeam => widget.team;

  Team _resolveTeam() {
    for (final team in _auth.teams) {
      if (team.id == _initialTeam.id) return team;
    }
    if (_auth.activeTeam.value?.id == _initialTeam.id) {
      return _auth.activeTeam.value!;
    }
    return _initialTeam;
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  Future<void> _copyTeamCode(Team team) async {
    await Clipboard.setData(ClipboardData(text: team.teamCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('团队号已复制')),
    );
  }

  Future<void> _pickBrand(Team team) async {
    final selected = await context.push<TeamBrandSelection>(
      AppPaths.teamBrandPicker,
    );
    if (selected == null || !mounted) return;
    _auth.updateTeam(team.copyWith(brandImagePath: selected.imagePath));
  }

  Future<void> _editTeamName(Team team) async {
    final controller = TextEditingController(text: team.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('团队名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入团队名称',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newName == null || newName == team.name || !mounted) return;
    _auth.updateTeam(team.copyWith(name: newName));
  }

  Future<void> _pickIndustry(Team team) async {
    final selected = await context.push<String>(
      AppPaths.teamIndustryPicker,
      extra: team.industryType,
    );
    if (selected == null || !mounted) return;
    _auth.updateTeam(team.copyWith(industryType: selected));
  }

  Future<void> _confirmLeaveTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出此团队'),
          content: Text('确定退出「${team.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '退出',
                style: TextStyle(color: Color(0xFFE64545)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    _auth.leaveTeam(team.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出团队')),
    );

    if (_auth.teams.isEmpty) {
      context.go(AppPaths.camera);
      return;
    }

    context.go(AppPaths.teamWorkspace, extra: _auth.activeTeam.value?.id);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    _auth.logout();
    if (!mounted) return;
    context.go(AppPaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '团队信息',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showComingSoon('更多操作'),
            icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
          ),
        ],
      ),
      body: Obx(() {
        final team = _resolveTeam();

        return Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        label: '团队头像',
                        onTap: () => _pickBrand(team),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TeamAvatarBadge(team: team),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                      _InfoRow(
                        label: '团队名称',
                        value: team.name,
                        onTap: () => _editTeamName(team),
                      ),
                      _InfoRow(
                        label: '所属行业',
                        value: team.industryType,
                        onTap: () => _pickIndustry(team),
                      ),
                      _InfoRow(
                        label: '团队号',
                        showChevron: false,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              team.teamCode,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _copyTeamCode(team),
                              child: const Text(
                                '复制',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _InfoRow(
                        label: '团队二维码',
                        onTap: () => _showComingSoon('团队二维码'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 22,
                              color: Colors.grey.shade700,
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () => _confirmLeaveTeam(team),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: const Text(
                          '退出此团队',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFE64545),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? 8 : 16),
                child: TextButton(
                  onPressed: _confirmLogout,
                  child: Text(
                    '我要退出登录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (showChevron)
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }

    return Column(
      children: [
        content,
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            color: Colors.grey.shade200,
          ),
      ],
    );
  }
}

class _TeamAvatarBadge extends StatelessWidget {
  const _TeamAvatarBadge({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    Widget badge = _buildAvatar();

    return Badge(
      label: const Text('1', style: TextStyle(fontSize: 10)),
      backgroundColor: const Color(0xFFE64545),
      child: badge,
    );
  }

  Widget _buildAvatar() {
    final brandPath = team.brandImagePath;
    if (brandPath != null && brandPath.isNotEmpty) {
      final file = File(brandPath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            file,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        team.name.isNotEmpty ? team.name.substring(0, 1) : '团',
        style: const TextStyle(
          color: Color(0xFF1677FF),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
