import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';

class TeamMemberFilterResult {
  const TeamMemberFilterResult({required this.memberIds});

  final Set<String> memberIds;

  bool get hasFilter => memberIds.isNotEmpty;
}

Future<TeamMemberFilterResult?> showTeamMemberFilterSheet(
  BuildContext context, {
  required String teamId,
  Set<String>? initialSelectedMemberIds,
}) {
  return showModalBottomSheet<TeamMemberFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => TeamMemberFilterSheet(
      teamId: teamId,
      initialSelectedMemberIds: initialSelectedMemberIds ?? const {},
    ),
  );
}

class TeamMemberFilterSheet extends StatefulWidget {
  const TeamMemberFilterSheet({
    super.key,
    required this.teamId,
    required this.initialSelectedMemberIds,
  });

  final String teamId;
  final Set<String> initialSelectedMemberIds;

  @override
  State<TeamMemberFilterSheet> createState() => _TeamMemberFilterSheetState();
}

class _TeamMemberFilterSheetState extends State<TeamMemberFilterSheet> {
  static const _primaryBlue = Color(0xFF1677FF);

  final _searchController = TextEditingController();
  late Set<String> _selectedMemberIds;
  String _keyword = '';

  TeamWorkspaceService get _workspace => Get.find<TeamWorkspaceService>();

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = Set<String>.from(widget.initialSelectedMemberIds);
    _searchController.addListener(() {
      setState(() => _keyword = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TeamMember> get _allMembers =>
      _workspace.membersForTeam(widget.teamId);

  List<TeamMember> get _filteredMembers {
    if (_keyword.isEmpty) return _allMembers;
    return _allMembers
        .where((member) => member.name.contains(_keyword))
        .toList();
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedMemberIds.clear());
  }

  void _confirm() {
    Navigator.pop(
      context,
      TeamMemberFilterResult(memberIds: Set<String>.from(_selectedMemberIds)),
    );
  }

  String _roleLabel(TeamMember member) {
    if (member.role == TeamMemberRole.owner) return member.roleLabel;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.62;
    final members = _filteredMembers;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '筛选成员',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '请输入姓名/手机号搜索',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: members.isEmpty
                    ? Center(
                        child: Text(
                          '未找到匹配成员',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: members.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final selected =
                              _selectedMemberIds.contains(member.id);
                          final roleLabel = _roleLabel(member);
                          return InkWell(
                            onTap: () => _toggleMember(member.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? _primaryBlue
                                        : Colors.grey.shade400,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  _MemberAvatar(text: member.avatarText),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (roleLabel.isNotEmpty)
                                    Text(
                                      roleLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap:
                          _selectedMemberIds.isEmpty ? null : _clearSelection,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 22,
                              color: _selectedMemberIds.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '清空',
                              style: TextStyle(
                                fontSize: 13,
                                color: _selectedMemberIds.isEmpty
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '确认(${_selectedMemberIds.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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
  const _MemberAvatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
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
