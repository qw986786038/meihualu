import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/gallery/ai_remove_watermark_controller.dart';
import 'package:watermark_camera/pages/gallery/ai_remove_watermark_result_page.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class AiRemoveWatermarkPickerPage extends StatefulWidget {
  const AiRemoveWatermarkPickerPage({super.key});

  @override
  State<AiRemoveWatermarkPickerPage> createState() =>
      _AiRemoveWatermarkPickerPageState();
}

class _AiRemoveWatermarkPickerPageState
    extends State<AiRemoveWatermarkPickerPage> {
  final AiRemoveWatermarkController controller =
      Get.put(AiRemoveWatermarkController());

  @override
  void dispose() {
    if (Get.isRegistered<AiRemoveWatermarkController>()) {
      Get.delete<AiRemoveWatermarkController>();
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
    if (!controller.isRemovable(asset)) {
      _showSnack('仅支持去除本应用「梅花鹿」相册中的水印');
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AiRemoveWatermarkResultPage(asset: asset),
      ),
    );
    if (saved == true) {
      await controller.loadInitialAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildHintSection(),
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
                    title: '暂无本应用水印照片或视频',
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
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
      child: Row(
        children: [
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
            onPressed: () => context.pop(),
            child: const Text(
              '取消',
              style: TextStyle(
                color: _kPrimaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '请选择本应用水印照片或视频',
            style: TextStyle(
              color: _kPrimaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '仅显示「梅花鹿」相册中的内容，其他应用水印无法去除',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 13,
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
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
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
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = group.assets[index];
                      final removable = controller.isRemovable(asset);
                      return _RemovableThumbnail(
                        asset: asset,
                        removable: removable,
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

class _RemovableThumbnail extends StatelessWidget {
  const _RemovableThumbnail({
    required this.asset,
    required this.removable,
    required this.onTap,
  });

  final AssetEntity asset;
  final bool removable;
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
            child: ColorFiltered(
              colorFilter: removable
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.55),
                      BlendMode.srcATop,
                    ),
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
                        child:
                            Icon(Icons.image_outlined, color: Colors.white54),
                      ),
                    );
                  }
                  return Opacity(
                    opacity: removable ? 1 : 0.45,
                    child: Image.memory(data, fit: BoxFit.cover),
                  );
                },
              ),
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
          if (!removable)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white70,
                ),
                alignment: Alignment.center,
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
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
