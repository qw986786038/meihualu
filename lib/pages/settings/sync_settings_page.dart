import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/services/auth_service.dart';

class SyncSettingsPage extends StatelessWidget {
  const SyncSettingsPage({super.key});

  AuthService get _auth => Get.find<AuthService>();

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        title: const Text(
          '同步设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '个人同步设置'),
          Obx(
            () => _PersonalSyncTile(
              value: _auth.skipLocalSaveAfterSync.value,
              onChanged: (value) => _auth.skipLocalSaveAfterSync.value = value,
            ),
          ),
          const SizedBox(height: 12),
          const _SectionHeader(title: '团队同步设置'),
          _TeamSyncTile(
            title: '高清原图',
            onTap: () => _showComingSoon(context, '高清原图'),
          ),
          _divider(),
          _TeamSyncTile(
            title: '无水印照片',
            onTap: () => _showComingSoon(context, '无水印照片'),
          ),
          _divider(),
          _TeamSyncTile(
            title: '无右下角水印',
            onTap: () => _showComingSoon(context, '无右下角水印'),
          ),
          _divider(),
          _TeamSyncTile(
            title: '同步团队照片不保存到本地',
            onTap: () => _showComingSoon(context, '同步团队照片不保存到本地'),
          ),
          _divider(),
          _TeamSyncTile(
            title: '没有地点的照片不允许自动上传',
            onTap: () => _showComingSoon(context, '没有地点的照片不允许自动上传'),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: const Color(0xFFF5F6F8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _PersonalSyncTile extends StatelessWidget {
  const _PersonalSyncTile({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '同步团队照片不保存本地',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '省内存，工作照/生活照分开',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: value,
              activeTrackColor: const Color(0xFF34C759),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSyncTile extends StatelessWidget {
  const _TeamSyncTile({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 18,
                color: Color(0xFFE8A317),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 22,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
