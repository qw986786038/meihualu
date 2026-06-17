import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/widgets/photo_sync_settings_sheet.dart';

class WorkModeBar extends StatelessWidget {
  const WorkModeBar({super.key});

  Future<void> _openLoginThenSyncSheet(
    BuildContext context, {
    WorkMode focusMode = WorkMode.personal,
  }) async {
    final loggedIn = await context.push<bool>(AppPaths.login);
    if (loggedIn != true || !context.mounted) return;

    Get.find<AuthService>().setWorkMode(focusMode);

    // 等登录页 pop 完成后再弹 bottom sheet，避免弹窗被吞掉
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!context.mounted) return;

    await showPhotoSyncSettingsSheet(context, focusMode: focusMode);
  }

  Future<void> _showSyncSheet(BuildContext context) async {
    Get.find<AuthService>().setWorkMode(WorkMode.personal);

    await SchedulerBinding.instance.endOfFrame;
    if (!context.mounted) return;

    await showPhotoSyncSettingsSheet(
      context,
      focusMode: WorkMode.personal,
    );
  }

  Future<void> _handlePersonalTap(BuildContext context, AuthService auth) async {
    if (!auth.isLoggedIn.value) {
      await _openLoginThenSyncSheet(context, focusMode: WorkMode.personal);
      return;
    }
    await _showSyncSheet(context);
  }

  Future<void> _handleTeamTap(BuildContext context, AuthService auth) async {
    auth.setWorkMode(WorkMode.team);
    final teamId = auth.activeTeam.value?.id;
    await context.push(AppPaths.teamWorkspace, extra: teamId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Obx(() {
      final isLoggedIn = auth.isLoggedIn.value;
      final isPersonal = auth.workMode.value == WorkMode.personal;
      final isTeam = auth.workMode.value == WorkMode.team;
      final personalSpaceName = auth.personalSpace.value?.name;

      return Container(
        height: 44,
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: _ModeSide(
                backgroundColor: isLoggedIn && isPersonal
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFFEFEFEF),
                onTap: () => _handlePersonalTap(context, auth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        isLoggedIn
                            ? (personalSpaceName ?? auth.userName.value)
                            : '立即登录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isLoggedIn && isPersonal
                              ? const Color(0xFF333333)
                              : const Color(0xFF666666),
                          fontWeight: isLoggedIn && isPersonal
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (!isLoggedIn) ...[
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: _ModeSide(
                backgroundColor: isLoggedIn && isTeam
                    ? const Color(0xFFDCEEFF)
                    : const Color(0xFFEAF4FF),
                onTap: () => _handleTeamTap(context, auth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '我的团队',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isLoggedIn && isTeam
                              ? const Color(0xFF1677FF)
                              : const Color(0xFF333333),
                          fontWeight: isLoggedIn && isTeam
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.groups_outlined,
                      size: 18,
                      color: isLoggedIn && isTeam
                          ? const Color(0xFF1677FF)
                          : const Color(0xFF666666),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ModeSide extends StatelessWidget {
  const _ModeSide({
    required this.backgroundColor,
    required this.onTap,
    required this.child,
  });

  final Color backgroundColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}
