import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/camera/image_tagging_controller.dart';
import 'package:watermark_camera/pages/camera/screen_text_recognition_flow.dart';
import 'package:watermark_camera/services/aliyun_ocr_service.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class ScreenTextOcrPickerPage extends StatefulWidget {
  const ScreenTextOcrPickerPage({super.key});

  @override
  State<ScreenTextOcrPickerPage> createState() =>
      _ScreenTextOcrPickerPageState();
}

class _ScreenTextOcrPickerPageState extends State<ScreenTextOcrPickerPage> {
  final ImageTaggingController controller = Get.put(ImageTaggingController());
  final AliyunOcrService ocrService = Get.find<AliyunOcrService>();
  bool _isRecognizing = false;

  @override
  void dispose() {
    if (Get.isRegistered<ImageTaggingController>()) {
      Get.delete<ImageTaggingController>();
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
    if (_isRecognizing) return;

    setState(() => _isRecognizing = true);
    try {
      final bytes = await _loadAssetBytes(asset);
      if (!mounted) return;
      if (bytes == null) {
        _showSnack('读取图片失败');
        return;
      }
      await recognizeScreenTextBytes(
        context: context,
        ocrService: ocrService,
        bytes: bytes,
        asset: asset,
        onError: _showSnack,
      );
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  void _requestCapture() {
    if (_isRecognizing) return;
    context.pop(kScreenTextCaptureAction);
  }

  Future<Uint8List?> _loadAssetBytes(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;
    return file.readAsBytes();
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
            _buildActionSection(),
            Expanded(
              child: Stack(
                children: [
                  Obx(() {
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
                        title: '暂无照片',
                        actionLabel: '刷新',
                        onAction: controller.loadInitialAssets,
                      );
                    }
                    return _buildGallery();
                  }),
                  if (_isRecognizing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      alignment: Alignment.center,
                      child: const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('正在识别屏幕文字...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const Expanded(
            child: Text(
              '屏幕文字识别',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _isRecognizing ? null : _requestCapture,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('拍照识别 LED 屏幕'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '或从相册选择',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
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
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return Obx(() {
      final groups = controller.groupedAssets;
      var globalIndex = 0;
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 240) {
            controller.loadMoreIfNeeded(controller.assets.length - 1);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: groups.length,
          itemBuilder: (context, groupIndex) {
            final group = groups[groupIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.assets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final asset = group.assets[index];
                    final currentIndex = globalIndex++;
                    controller.loadMoreIfNeeded(currentIndex);
                    return GestureDetector(
                      onTap: () => _onAssetTap(asset),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _AssetThumbnail(
                          asset: asset,
                          size: const ThumbnailSize.square(300),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

class _AssetThumbnail extends StatelessWidget {
  const _AssetThumbnail({
    required this.asset,
    required this.size,
  });

  final AssetEntity asset;
  final ThumbnailSize size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(size, quality: 80),
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
    );
  }
}
