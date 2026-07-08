import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';

Future<void> showPhotoSyncSettingsSheet(
  BuildContext context, {
  WorkMode focusMode = WorkMode.personal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF5F6F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => PhotoSyncSettingsSheet(focusMode: focusMode),
  );
}

class PhotoSyncSettingsSheet extends StatelessWidget {
  const PhotoSyncSettingsSheet({
    super.key,
    this.focusMode = WorkMode.personal,
  });

  final WorkMode focusMode;

  AuthService get _auth => Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SheetHeader(
                  onSettingsTap: () {
                    Navigator.pop(context);
                    context.push(AppPaths.syncSettings);
                  },
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final teams = _auth.teams;
                  if (teams.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      _SectionCard(
                        highlighted: focusMode == WorkMode.team,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '我的团队',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...List.generate(teams.length, (index) {
                              final team = teams[index];
                              return Column(
                                children: [
                                  if (index > 0)
                                    Divider(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                  _TeamSyncRow(
                                    team: team,
                                    onOpen: () {
                                      Navigator.pop(context);
                                      context.push(
                                        AppPaths.teamWorkspace,
                                        extra: team.id,
                                      );
                                    },
                                    onSyncChanged: (enabled) =>
                                        _auth.setTeamSyncEnabled(
                                      enabled,
                                      teamId: team.id,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                Obx(() {
                  final space = _auth.personalSpace.value;
                  if (space == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _SectionCard(
                        highlighted: focusMode == WorkMode.personal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '个人空间',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push(AppPaths.personalSpace);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      children: [
                                        _AvatarBadge(text: space.avatarText),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      space.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    size: 20,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '仅自己可见',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: space.syncEnabled,
                                  activeTrackColor: const Color(0xFF34C759),
                                  onChanged: _auth.setPersonalSyncEnabled,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                Obx(() {
                  if (_auth.hasTeam) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _SectionCard(
                        highlighted: focusMode == WorkMode.team,
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await context.push(AppPaths.createTeam);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF34C759),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('创建团队'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await context.push(AppPaths.joinTeam);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1677FF),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  minimumSize: const Size.fromHeight(44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('加入团队'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                Obx(
                  () => _SectionCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android_outlined,
                          size: 28,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '同步后不保存本地',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '省内存，工作照/生活照分开',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _auth.skipLocalSaveAfterSync.value,
                          onChanged: (value) =>
                              _auth.skipLocalSaveAfterSync.value = value,
                        ),
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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '拍照自动同步',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onSettingsTap,
          icon: Icon(Icons.settings_outlined, size: 18, color: Colors.grey.shade600),
          label: Text(
            '设置',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.highlighted = false,
  });

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlighted
            ? Border.all(color: const Color(0xFF1677FF).withValues(alpha: 0.35))
            : null,
      ),
      child: child,
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.text});

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

class _TeamSyncRow extends StatelessWidget {
  const _TeamSyncRow({
    required this.team,
    required this.onOpen,
    required this.onSyncChanged,
  });

  final Team team;
  final VoidCallback onOpen;
  final ValueChanged<bool> onSyncChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                _TeamBrandBadge(team: team),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Switch.adaptive(
          value: team.syncEnabled,
          activeTrackColor: const Color(0xFF34C759),
          onChanged: onSyncChanged,
        ),
      ],
    );
  }
}

class _TeamBrandBadge extends StatelessWidget {
  const _TeamBrandBadge({required this.team});

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
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    final name = team.name;
    return _AvatarBadge(
      text: name.isNotEmpty ? name.substring(0, 1) : '团',
    );
  }
}
