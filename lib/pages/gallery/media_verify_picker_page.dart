import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/gallery/media_verify_picker_controller.dart';
import 'package:watermark_camera/pages/gallery/media_verify_result_page.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class MediaVerifyPickerPage extends StatefulWidget {
  const MediaVerifyPickerPage({super.key});

  @override
  State<MediaVerifyPickerPage> createState() => _MediaVerifyPickerPageState();
}

class _MediaVerifyPickerPageState extends State<MediaVerifyPickerPage> {
  final MediaVerifyPickerController controller =
      Get.put(MediaVerifyPickerController());

  @override
  void dispose() {
    if (Get.isRegistered<MediaVerifyPickerController>()) {
      Get.delete<MediaVerifyPickerController>();
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
    if (asset.type == AssetType.video) {
      _showSnack('暂仅支持校验照片');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MediaVerifyResultPage(asset: asset),
      ),
    );
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择要校验的照片或视频',
                    style: TextStyle(
                      color: _kPrimaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '请选择本应用拍摄并带有防伪码的照片',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                  ),
                ],
              ),
            ),
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
                    title: '暂无照片或视频',
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
            child: Text(
              '照片验真',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                      return _VerifyThumbnail(
                        asset: asset,
                        onTap: () => _onAssetTap(asset),
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

class _VerifyThumbnail extends StatelessWidget {
  const _VerifyThumbnail({
    required this.asset,
    required this.onTap,
  });

  final AssetEntity asset;
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 12, color: Colors.white),
                    Text(
                      '视频',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
