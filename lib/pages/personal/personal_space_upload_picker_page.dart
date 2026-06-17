import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/personal/personal_space_upload_controller.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';

const Color _kPrimaryBlue = Color(0xFF1677FF);

class PersonalSpaceUploadPickerPage extends StatefulWidget {
  const PersonalSpaceUploadPickerPage({
    super.key,
    this.mode = PersonalSpacePickerMode.upload,
  });

  final PersonalSpacePickerMode mode;

  @override
  State<PersonalSpaceUploadPickerPage> createState() =>
      _PersonalSpaceUploadPickerPageState();
}

class _PersonalSpaceUploadPickerPageState
    extends State<PersonalSpaceUploadPickerPage> {
  final PersonalSpaceUploadController controller =
      Get.put(PersonalSpaceUploadController());
  bool _isUploading = false;

  AuthService get _auth => Get.find<AuthService>();
  PersonalSpaceService get _personalService => Get.find<PersonalSpaceService>();

  @override
  void dispose() {
    if (Get.isRegistered<PersonalSpaceUploadController>()) {
      Get.delete<PersonalSpaceUploadController>();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onComplete() async {
    if (_isUploading) return;

    final assets = controller.selectedAssets;
    if (assets.isEmpty) {
      _showSnack('请先选择照片或视频');
      return;
    }

    if (widget.mode == PersonalSpacePickerMode.batch) {
      _showSnack('已选择 ${assets.length} 项，批量操作功能即将开放');
      return;
    }

    final space = resolvePersonalSpace(_auth);
    setState(() => _isUploading = true);
    try {
      var uploaded = 0;
      for (final asset in assets) {
        final file = await asset.file;
        if (file == null) continue;
        _personalService.addPhoto(
          personalSpaceId: space.id,
          filePath: file.path,
          capturedAt: asset.createDateTime,
          isVideo: asset.type == AssetType.video,
        );
        uploaded++;
      }

      if (!mounted) return;
      if (uploaded == 0) {
        _showSnack('上传失败，请重试');
        return;
      }
      context.pop(true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final message = controller.permissionMessage.value;
                if (message != null) {
                  return _buildEmptyState(
                    icon: Icons.photo_library_outlined,
                    title: message,
                    actionLabel: '重试',
                    onAction: controller.loadInitialAssets,
                  );
                }
                if (controller.visibleAssets.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.image_not_supported_outlined,
                    title: controller.activeTab.value ==
                            PersonalSpaceUploadTab.video
                        ? '暂无视频'
                        : '暂无图片或视频',
                    actionLabel: '刷新',
                    onAction: controller.loadInitialAssets,
                  );
                }
                return _buildGallery();
              }),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, size: 26),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '图片和视频',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 22),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showSnack('同步列表功能开发中，敬请期待'),
            child: const Text(
              '同步列表',
              style: TextStyle(
                color: _kPrimaryBlue,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            _TabChip(
              label: '全部',
              selected: controller.activeTab.value == PersonalSpaceUploadTab.all,
              onTap: () => controller.setActiveTab(PersonalSpaceUploadTab.all),
            ),
            const SizedBox(width: 24),
            _TabChip(
              label: '视频',
              badge: 'VIP',
              selected:
                  controller.activeTab.value == PersonalSpaceUploadTab.video,
              onTap: () =>
                  controller.setActiveTab(PersonalSpaceUploadTab.video),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Obx(() {
      final groups = controller.groupedAssets;
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 240) {
            controller.loadMoreIfNeeded(controller.visibleAssets.length);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '${group.title} (${group.assets.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const Spacer(),
                      _GroupSelectAllButton(
                        selected: controller.isGroupAllSelected(group.assets),
                        onTap: () =>
                            controller.toggleSelectAllForGroup(group.assets),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = group.assets[index];
                      return _SelectableThumbnail(
                        asset: asset,
                        isSelected: controller.isSelected(asset),
                        onTap: () => controller.toggleSelection(asset),
                      );
                    },
                    childCount: group.assets.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      );
    });
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final count = controller.selectedCount;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '您已选择照片/视频：$count',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            SizedBox(
              width: 96,
              height: 40,
              child: FilledButton(
                onPressed: count == 0 || _isUploading ? null : _onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  disabledBackgroundColor: const Color(0xFFBFD7FF),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('完成', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF111111) : Colors.grey.shade600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: selected ? _kPrimaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSelectAllButton extends StatelessWidget {
  const _GroupSelectAllButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kPrimaryBlue : Colors.transparent,
                border: Border.all(
                  color: selected ? _kPrimaryBlue : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              '全选',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableThumbnail extends StatelessWidget {
  const _SelectableThumbnail({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize.square(300),
                quality: 80,
              ),
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  return ColoredBox(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: Colors.white54),
                    ),
                  );
                }
                return Image.memory(data, fit: BoxFit.cover);
              },
            ),
          ),
          if (asset.type == AssetType.video)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _kPrimaryBlue : Colors.white70,
                border: Border.all(
                  color: isSelected ? _kPrimaryBlue : Colors.grey.shade500,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
