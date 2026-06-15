import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watermark_camera/models/team.dart';

class TeamInviteMembersPage extends StatefulWidget {
  const TeamInviteMembersPage({super.key, required this.team});

  final Team team;

  @override
  State<TeamInviteMembersPage> createState() => _TeamInviteMembersPageState();
}

class _TeamInviteMembersPageState extends State<TeamInviteMembersPage> {
  static const _allSuggestedColleagues = [
    _SuggestedColleague(name: '范冬梅', avatarText: '范'),
    _SuggestedColleague(name: '张建国', avatarText: '张'),
    _SuggestedColleague(name: '李晓明', avatarText: '李'),
    _SuggestedColleague(name: '王芳', avatarText: '王'),
  ];

  int _suggestionBatch = 0;

  Team get _team => widget.team;

  List<_SuggestedColleague> get _visibleSuggestions {
    final start = (_suggestionBatch * 1) % _allSuggestedColleagues.length;
    return [_allSuggestedColleagues[start]];
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  Future<void> _copyTeamCode() async {
    await Clipboard.setData(ClipboardData(text: _team.teamCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('团队号已复制')),
    );
  }

  void _refreshSuggestions() {
    setState(() {
      _suggestionBatch = (_suggestionBatch + 1) % _allSuggestedColleagues.length;
    });
  }

  void _addSuggestedColleague(_SuggestedColleague colleague) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已向${colleague.name}发送添加邀请')),
    );
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '添加成员',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _team.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF07C160),
              child: const Icon(Icons.wechat, color: Colors.white, size: 22),
            ),
            title: '微信邀请',
            onTap: () => _showComingSoon('微信邀请'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF333333),
              child: const Icon(Icons.qr_code_2, color: Colors.white, size: 22),
            ),
            title: '二维码邀请',
            onTap: () => _showComingSoon('二维码邀请'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF1677FF),
              child: const Icon(Icons.phonelink_ring, color: Colors.white, size: 20),
            ),
            title: '面对面邀请',
            onTap: () => _showComingSoon('面对面邀请'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF1677FF),
              child: const Icon(Icons.contacts_outlined, color: Colors.white, size: 22),
            ),
            title: '手机通讯录添加',
            onTap: () => _showComingSoon('手机通讯录添加'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF1677FF),
              child: const Icon(Icons.phone_outlined, color: Colors.white, size: 22),
            ),
            title: '输入手机号添加',
            onTap: () => _showComingSoon('输入手机号添加'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF1677FF),
              child: const Icon(Icons.computer_outlined, color: Colors.white, size: 22),
            ),
            title: '在电脑上批量添加',
            onTap: () => _showComingSoon('在电脑上批量添加'),
          ),
          _divider(),
          _InviteMethodTile(
            icon: _CircleIcon(
              color: const Color(0xFF1677FF),
              child: const Icon(Icons.more_horiz, color: Colors.white, size: 22),
            ),
            title: '钉钉、QQ邀请',
            onTap: () => _showComingSoon('钉钉、QQ邀请'),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  '也可以让成员下载今日水印相机APP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _copyTeamCode,
                  behavior: HitTestBehavior.opaque,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: '输入团队号 '),
                        TextSpan(
                          text: _team.teamCode,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' 加入团队'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '可能是你同事',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _refreshSuggestions,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
                      label: const Text('换一批', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._visibleSuggestions.map(
                  (colleague) => _SuggestedColleagueTile(
                    colleague: colleague,
                    onAdd: () => _addSuggestedColleague(colleague),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: Colors.grey.shade200,
    );
  }
}

class _SuggestedColleague {
  const _SuggestedColleague({required this.name, required this.avatarText});

  final String name;
  final String avatarText;
}

class _InviteMethodTile extends StatelessWidget {
  const _InviteMethodTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;

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
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

class _SuggestedColleagueTile extends StatelessWidget {
  const _SuggestedColleagueTile({
    required this.colleague,
    required this.onAdd,
  });

  final _SuggestedColleague colleague;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              colleague.avatarText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1677FF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  colleague.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '可能是你的同事',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1677FF),
              side: const BorderSide(color: Color(0xFF1677FF)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('添加', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
