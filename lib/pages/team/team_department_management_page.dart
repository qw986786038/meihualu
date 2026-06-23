import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/widgets/team_add_sub_department_sheet.dart';
import 'package:watermark_camera/pages/team/team_member_profile_page.dart';

class TeamDepartmentManagementPage extends StatefulWidget {
  const TeamDepartmentManagementPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamDepartmentManagementPage> createState() =>
      _TeamDepartmentManagementPageState();
}

class _TeamDepartmentManagementPageState
    extends State<TeamDepartmentManagementPage> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  Team get _team => widget.team;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  List<TeamMember> _filterMembers(List<TeamMember> members) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return members;
    return members.where((member) => member.name.contains(query)).toList();
  }

  Future<void> _openAddSubDepartmentSheet() async {
    final name = await showTeamAddSubDepartmentSheet(context);
    if (!mounted || name == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加子部门：$name')),
    );
  }

  Future<void> _openMemberProfile(TeamMember member) async {
    await context.push(
      AppPaths.teamMemberProfile,
      extra: TeamMemberProfileArgs(team: _team, member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '部门管理',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '关闭',
              style: TextStyle(fontSize: 15, color: _primaryBlue),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final members = _filterMembers(_workspace.membersForTeam(_team.id));

        return Column(
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
            Expanded(
              child: members.isEmpty
                  ? Center(
                      child: Text(
                        '暂无成员',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 72,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _DepartmentMemberTile(
                          member: member,
                          onTap: () => _openMemberProfile(member),
                        );
                      },
                    ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _openAddSubDepartmentSheet,
                        child: const Text(
                          '添加子部门',
                          style: TextStyle(
                            fontSize: 16,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _showComingSoon('更多设置'),
                        child: const Text(
                          '更多设置',
                          style: TextStyle(
                            fontSize: 16,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DepartmentMemberTile extends StatelessWidget {
  const _DepartmentMemberTile({
    required this.member,
    required this.onTap,
  });

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
            _MemberAvatar(text: member.avatarText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            if (member.role == TeamMemberRole.owner)
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.text});

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
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
