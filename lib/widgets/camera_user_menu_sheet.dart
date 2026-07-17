import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/config/api_config.dart';
import 'package:watermark_camera/models/api/user_info.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';

Future<void> showCameraUserMenuSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => const CameraUserMenuSheet(),
  );
}

class CameraUserMenuSheet extends StatefulWidget {
  const CameraUserMenuSheet({super.key});

  @override
  State<CameraUserMenuSheet> createState() => _CameraUserMenuSheetState();
}

class _CameraUserMenuSheetState extends State<CameraUserMenuSheet> {
  bool _isLoadingProfile = false;

  AuthService get _auth => Get.find<AuthService>();

  Future<void> _refreshProfile() async {
    if (!_auth.isLoggedIn.value || _isLoadingProfile) return;
    setState(() => _isLoadingProfile = true);
    await _auth.fetchUserInfo();
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<void> _openLogin() async {
    Navigator.of(context).pop();
    await context.push<bool>(AppPaths.login);
  }

  Future<void> _openProfile() async {
    Navigator.of(context).pop();
    if (!mounted) return;
    await context.push(AppPaths.userProfile);
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
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    if (_auth.isLoggedIn.value && _auth.userInfo.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_refreshProfile());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Obx(() {
      final loggedIn = _auth.isLoggedIn.value;
      final info = _auth.userInfo.value;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!loggedIn) ...[
                const Text(
                  '登录后可查看个人资料并同步照片',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _openLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('立即登录'),
                ),
              ] else ...[
                _ProfileHeader(
                  info: info,
                  fallbackName: _auth.userName.value,
                  isLoading: _isLoadingProfile,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('个人资料'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openProfile,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.workspace_premium_outlined,
                    color: Color(0xFFFF8A3D),
                  ),
                  title: const Text('个人会员'),
                  subtitle: const Text('开通会员解锁权益'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AppPaths.personalMembership);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Color(0xFFFF4D4F)),
                  title: const Text(
                    '退出登录',
                    style: TextStyle(color: Color(0xFFFF4D4F)),
                  ),
                  onTap: _logout,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.info,
    required this.fallbackName,
    required this.isLoading,
  });

  final UserInfo? info;
  final String fallbackName;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ApiConfig.resolveAssetUrl(info?.avatarUrl);
    final displayName = info?.displayName ?? fallbackName;
    final phoneText = info?.phone ?? '';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEAF3FF),
          backgroundImage:
              avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? Text(
                  displayName.isNotEmpty ? displayName.substring(0, 1) : '我',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1677FF),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (isLoading)
                Text(
                  '资料加载中...',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                )
              else if (phoneText.isNotEmpty)
                Text(
                  phoneText,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
