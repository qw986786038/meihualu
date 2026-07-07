import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = false;

  AuthService get _auth => Get.find<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _auth.fetchUserInfo();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openEditProfile() async {
    final updated = await context.push<bool>(AppPaths.editProfile);
    if (updated == true && mounted) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出当前账号吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    _auth.logout();
    if (!mounted) return;
    context.go(AppPaths.camera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Obx(() {
        final info = _auth.userInfo.value;

        if (_isLoading && info == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (info == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _auth.lastErrorMessage.value.isNotEmpty
                      ? _auth.lastErrorMessage.value
                      : '暂无个人资料',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadProfile,
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        }

        final avatarUrl = ApiConfig.resolveAssetUrl(info.avatarUrl);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFFEAF3FF),
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(
                        info.displayName.isNotEmpty
                            ? info.displayName.substring(0, 1)
                            : '我',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1677FF),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _InfoTile(label: '手机号', value: info.phone),
            _InfoTile(label: '昵称', value: info.nickName ?? '未设置'),
            _InfoTile(label: '用户名', value: info.userName ?? '未设置'),
            _InfoTile(label: '性别', value: info.sexLabel),
            _InfoTile(label: '邮箱', value: _displayOrPlaceholder(info.email)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _openEditProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('修改个人资料'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFFFF4D4F),
                side: const BorderSide(color: Color(0xFFFF4D4F)),
              ),
              child: const Text('退出登录'),
            ),
          ],
        );
      }),
    );
  }

  String _displayOrPlaceholder(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return '未设置';
    return text;
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
