import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:watermark_camera/pages/gallery/latest_media_preview_page.dart';
import 'package:watermark_camera/pages/gallery/media_gallery_controller.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);
const Color _kLightBlueBg = Color(0xFFEAF3FF);

class MediaGalleryPage extends StatefulWidget {
  const MediaGalleryPage({super.key});

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  final MediaGalleryController controller = Get.put(MediaGalleryController());

  @override
  void dispose() {
    if (Get.isRegistered<MediaGalleryController>()) {
      Get.delete<MediaGalleryController>();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onAssetTap(AssetEntity asset) async {
    final feature = controller.activeFeature.value;
    if (feature != null) {
      controller.selectSingle(asset);
      _showSnack(
        '已选择 1 项，${controller.featureLabel(feature)}功能即将开放',
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LatestMediaPreviewPage(asset: asset),
      ),
    );
  }

  void _onFeatureTap(MediaGalleryFeature feature) {
    controller.activateFeature(feature);
    final needsMulti = feature == MediaGalleryFeature.collageReport ||
        feature == MediaGalleryFeature.batchAddWatermark ||
        feature == MediaGalleryFeature.batchRemoveWatermark ||
        feature == MediaGalleryFeature.batchEditWatermark;
    _showSnack(
      needsMulti
          ? '请选择图片，${controller.featureLabel(feature)}'
          : '请选择一张照片，${controller.featureLabel(feature)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
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
                if (controller.assets.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.image_not_supported_outlined,
                    title: '暂无图片或视频',
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
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, size: 26),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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
            onPressed: () => context.push(AppPaths.mediaMultiSelect),
            child: const Text(
              '多选',
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

  Widget _buildGallery() {
    return Obx(() {
      final groups = controller.groupedAssets;
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 240) {
            controller.loadMoreIfNeeded(controller.assets.length);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
          SliverToBoxAdapter(child: _buildFeatureSection()),
          for (final group in groups) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  '${group.title} (${group.assets.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = group.assets[index];
                    return _MediaThumbnail(
                      asset: asset,
                      isSelected: controller.isSelected(asset),
                      showSelection: controller.activeFeature.value != null,
                      onTap: () => _onAssetTap(asset),
                    );
                  },
                  childCount: group.assets.length,
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      );
    });
  }

  Widget _buildFeatureSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PrimaryFeatureCard(
                  icon: Icons.edit_outlined,
                  label: '编辑水印',
                  onTap: () =>
                      _onFeatureTap(MediaGalleryFeature.editWatermark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryFeatureCard(
                  icon: Icons.auto_fix_high_outlined,
                  label: 'AI去水印',
                  onTap: () => context.push(AppPaths.aiRemoveWatermark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SecondaryFeatureButton(
                icon: Icons.grid_view_rounded,
                label: '拼图汇报',
                onTap: () =>
                    _onFeatureTap(MediaGalleryFeature.collageReport),
              ),
              _SecondaryFeatureButton(
                icon: Icons.branding_watermark_outlined,
                label: '批量加水印',
                onTap: () =>
                    _onFeatureTap(MediaGalleryFeature.batchAddWatermark),
              ),
              _SecondaryFeatureButton(
                icon: Icons.layers_clear_outlined,
                label: '批量去水印',
                onTap: () =>
                    _onFeatureTap(MediaGalleryFeature.batchRemoveWatermark),
              ),
              _SecondaryFeatureButton(
                icon: Icons.drive_file_rename_outline,
                label: '批量编辑水印',
                onTap: () =>
                    _onFeatureTap(MediaGalleryFeature.batchEditWatermark),
              ),
            ],
          ),
        ],
      ),
    );
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

class _PrimaryFeatureCard extends StatelessWidget {
  const _PrimaryFeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kPrimaryBlue,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryFeatureButton extends StatelessWidget {
  const _SecondaryFeatureButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kLightBlueBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kPrimaryBlue, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF444444)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.asset,
    required this.isSelected,
    required this.showSelection,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool isSelected;
  final bool showSelection;
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
                const ThumbnailSize.square(240),
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
          if (showSelection)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
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
