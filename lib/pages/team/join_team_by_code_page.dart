import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/services/auth_service.dart';

class JoinTeamByCodePage extends StatefulWidget {
  const JoinTeamByCodePage({super.key});

  @override
  State<JoinTeamByCodePage> createState() => _JoinTeamByCodePageState();
}

class _JoinTeamByCodePageState extends State<JoinTeamByCodePage> {
  final _codeController = TextEditingController();
  final _helpTapRecognizer = TapGestureRecognizer();
  bool _isSearching = false;
  List<Team> _results = const [];

  AuthService get _auth => Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    _helpTapRecognizer.onTap = _showTeamCodeHelp;
  }

  bool get _canSearch =>
      _codeController.text.trim().isNotEmpty && !_isSearching;

  Future<void> _search() async {
    if (!_canSearch) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _results = const [];
    });

    final results = await _auth.searchTeamsByCode(_codeController.text.trim());
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _results = results;
    });

    if (results.isEmpty) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '未找到该团队号，请检查后重试',
      );
    }
  }

  Future<void> _joinTeam(Team team) async {
    setState(() => _isSearching = true);
    final success = await _auth.joinTeam(team);
    if (!mounted) return;

    setState(() => _isSearching = false);
    if (!success) {
      _showMessage(
        _auth.lastErrorMessage.value.isNotEmpty
            ? _auth.lastErrorMessage.value
            : '加入团队失败',
      );
      return;
    }

    _showMessage('加入团队成功');
    context.pop(true);
  }

  void _showTeamCodeHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('团队号在哪里？'),
          content: const Text(
            '已加入团队的成员可在「团队 - 管理 - 团队号」中查看团队号，'
            '向同事索取后即可在此输入加入。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _helpTapRecognizer.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '加入团队',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            '输入团队号',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: '向已加入的同事获取团队号（团队-管理-团队号）',
                ),
                TextSpan(
                  text: ' 团队号在哪里？',
                  style: const TextStyle(
                    color: Color(0xFF1677FF),
                  ),
                  recognizer: _helpTapRecognizer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _canSearch ? (_) => _search() : null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '输入团队号...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _canSearch ? _search : null,
                style: TextButton.styleFrom(
                  foregroundColor: _canSearch
                      ? const Color(0xFF1677FF)
                      : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '搜索',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '搜索结果',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            ..._results.map(
              (team) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TeamResultTile(
                  team: team,
                  onTap: () => _joinTeam(team),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamResultTile extends StatelessWidget {
  const _TeamResultTile({
    required this.team,
    required this.onTap,
  });

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1677FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  team.name.isNotEmpty ? team.name.substring(0, 1) : '团',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.teamCode.isNotEmpty
                          ? '团队号：${team.teamCode}'
                          : '点击申请加入',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
