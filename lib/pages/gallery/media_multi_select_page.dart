import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/gallery/media_multi_select_controller.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class MediaMultiSelectPage extends StatefulWidget {
  const MediaMultiSelectPage({super.key});

  @override
  State<MediaMultiSelectPage> createState() => _MediaMultiSelectPageState();
}

class _MediaMultiSelectPageState extends State<MediaMultiSelectPage> {
  final MediaMultiSelectController controller =
      Get.put(MediaMultiSelectController());

  @override
  void dispose() {
    if (Get.isRegistered<MediaMultiSelectController>()) {
      Get.delete<MediaMultiSelectController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilterBar(),
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
                    title: controller.onlyTodayWatermark.value
                        ? '今日暂无水印照片'
                        : '暂无图片或视频',
                    actionLabel: '刷新',
                    onAction: controller.loadInitialAssets,
                  );
                }
                return _buildGallery();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      child: Row(
        children: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '取消',
              style: TextStyle(color: _kPrimaryBlue, fontSize: 16),
            ),
          ),
          Expanded(
            child: Obx(
              () => Text(
                '已选择${controller.selectedCount}项',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: controller.onlyTodayWatermark.value,
                activeColor: _kPrimaryBlue,
                side: BorderSide(color: Colors.grey.shade400),
                onChanged: (value) =>
                    controller.toggleOnlyTodayWatermark(value ?? false),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '只展示今日水印照片',
              style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
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
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
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
