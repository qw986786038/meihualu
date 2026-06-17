import 'dart:io';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/models/personal_album_photo.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/widgets/work_mode_switch_sheet.dart';

class PersonalSpacePage extends StatefulWidget {
  const PersonalSpacePage({super.key});

  static const debugSpace = PersonalSpace(
    id: 'debug_personal',
    name: '李的空间',
    avatarText: '李',
  );

  @override
  State<PersonalSpacePage> createState() => _PersonalSpacePageState();
}

class _PersonalSpacePageState extends State<PersonalSpacePage> {
  static const _primaryBlue = Color(0xFF1677FF);

  AuthService get _auth => Get.find<AuthService>();
  PersonalSpaceService get _personalService => Get.find<PersonalSpaceService>();

  PersonalSpace get _space => resolvePersonalSpace(_auth);

  @override
  void initState() {
    super.initState();
    _auth.setWorkMode(WorkMode.personal);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature功能开发中，敬请期待')),
    );
  }

  Future<void> _openWorkModeSwitchSheet() async {
    await showWorkModeSwitchSheet(
      context,
      currentTeam: _auth.activeTeam.value,
      currentWorkspace: WorkspaceContext.personal,
    );
  }

  Future<void> _openCreateOrJoinTeam() async {
    await showWorkModeSwitchSheet(
      context,
      currentTeam: _auth.activeTeam.value,
      currentWorkspace: WorkspaceContext.personal,
    );
  }

  String _formatDateGroup(DateTime date, int count) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month月$day日·$count张';
  }

  Map<DateTime, List<PersonalAlbumPhoto>> _groupPhotosByDay(
    List<PersonalAlbumPhoto> photos,
  ) {
    final grouped = <DateTime, List<PersonalAlbumPhoto>>{};
    for (final photo in photos) {
      final day = DateTime(
        photo.capturedAt.year,
        photo.capturedAt.month,
        photo.capturedAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(photo);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                final photos = _personalService.photosForSpace(_space.id);
                final syncedPhotos =
                    photos.where((photo) => photo.filePath.isNotEmpty).toList();
                final groupedPhotos = _groupPhotosByDay(syncedPhotos);
                final sortedDays = groupedPhotos.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: _buildQuickActions()),
                    SliverToBoxAdapter(child: _buildStatsRow()),
                    SliverToBoxAdapter(child: _buildGalleryHeader(syncedPhotos.length)),
                    if (syncedPhotos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            '暂无照片\n开启拍照自动同步后，拍摄的照片会显示在这里',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                          ),
                        ),
                      )
                    else
                      ...sortedDays.map((day) {
                        final dayPhotos = groupedPhotos[day]!;
                        return SliverToBoxAdapter(
                          child: _PhotoDaySection(
                            title: _formatDateGroup(day, dayPhotos.length),
                            photos: dayPhotos,
                          ),
                        );
                      }),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: const Color(0xFF333333),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _openWorkModeSwitchSheet,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          label: const Text('1', style: TextStyle(fontSize: 10)),
                          child: Text(
                            _space.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_more, size: 20, color: Colors.grey.shade700),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _openCreateOrJoinTeam,
              child: const Text(
                '创建/加入团队',
                style: TextStyle(fontSize: 14, color: _primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        readOnly: true,
        onTap: () => _showComingSoon('搜索'),
        decoration: InputDecoration(
          hintText: '搜水印内容、拍摄地点...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _openUploadPicker() async {
    await context.push<bool>(AppPaths.personalSpaceUpload);
  }

  Future<void> _openBatchPicker() async {
    await context.push<bool>(AppPaths.personalSpaceBatch);
  }

  Widget _buildQuickActions() {
    const actions = [
      _QuickAction(icon: Icons.file_upload_outlined, label: '上传照片'),
      _QuickAction(icon: Icons.checklist_rtl, label: '批量操作'),
      _QuickAction(icon: Icons.computer_outlined, label: '电脑后台'),
      _QuickAction(icon: Icons.table_chart_outlined, label: '台账表'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Row(
        children: actions
            .map(
              (action) => Expanded(
                child: _QuickActionTile(
                  action: action,
                  onTap: switch (action.label) {
                    '上传照片' => _openUploadPicker,
                    '批量操作' => _openBatchPicker,
                    _ => () => _showComingSoon(action.label),
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatsRow() {
    const stats = [
      _StatItem(label: '我的水印', count: 1),
      _StatItem(label: '水印记录', count: 1),
      _StatItem(label: '我的拼图', count: 0),
      _StatItem(label: '我的地点', count: 0),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: stats
            .map(
              (stat) => Expanded(
                child: _StatTile(
                  stat: stat,
                  onTap: () => _showComingSoon(stat.label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGalleryHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Text(
            '全部照片 $count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => _showComingSoon('扩容'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF7A45),
              side: const BorderSide(color: Color(0xFFFF7A45)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('去扩容', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.onTap});

  final _QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(action.icon, size: 28, color: const Color(0xFF1677FF)),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.count});

  final String label;
  final int count;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat, required this.onTap});

  final _StatItem stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${stat.count}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PhotoDaySection extends StatelessWidget {
  const _PhotoDaySection({required this.title, required this.photos});

  final String title;
  final List<PersonalAlbumPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              return _PersonalPhotoTile(photo: photos[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _PersonalPhotoTile extends StatelessWidget {
  const _PersonalPhotoTile({required this.photo});

  final PersonalAlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.filePath);
    final hasFile = photo.filePath.isNotEmpty && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasFile)
            Image.file(file, fit: BoxFit.cover)
          else
            Container(
              color: const Color(0xFF2F2F2F),
              alignment: Alignment.center,
              child: Icon(Icons.photo_camera_outlined, color: Colors.grey.shade500, size: 36),
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: _PhotoWatermarkOverlay(photo: photo),
          ),
        ],
      ),
    );
  }
}

class _PhotoWatermarkOverlay extends StatelessWidget {
  const _PhotoWatermarkOverlay({required this.photo});

  final PersonalAlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final time = photo.capturedAt;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = weekdays[time.weekday - 1];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$hour:$minute',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} $weekday 多云 高温 35°C',
            style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.3),
          ),
          if (photo.location != null) ...[
            const SizedBox(height: 2),
            Text(
              photo.location!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.2),
            ),
          ],
        ],
      ),
    );
  }
}
