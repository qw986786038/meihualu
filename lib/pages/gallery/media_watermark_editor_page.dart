import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/router/app_paths.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/pages/gallery/media_watermark_editor_controller.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';
import 'package:watermark_camera/utils/media_overlay_compositor.dart';
import 'package:watermark_camera/utils/watermark_eligibility.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class MediaWatermarkEditorPage extends StatefulWidget {
  const MediaWatermarkEditorPage({
    super.key,
    required this.asset,
    this.autoOpenWatermarkSettings = false,
  });

  final AssetEntity asset;
  final bool autoOpenWatermarkSettings;

  @override
  State<MediaWatermarkEditorPage> createState() =>
      _MediaWatermarkEditorPageState();
}

class _MediaWatermarkEditorPageState extends State<MediaWatermarkEditorPage> {
  late final MediaWatermarkEditorController controller;
  final GlobalKey _previewKey = GlobalKey();
  final ScreenshotController _overlayScreenshotController =
      ScreenshotController();
  final TransformationController _imageTransformController =
      TransformationController();
  bool _didAutoOpenSettings = false;
  Worker? _loadWorker;
  Worker? _readyWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      MediaWatermarkEditorController(asset: widget.asset),
      tag: widget.asset.id,
    );
    _loadWorker = ever<bool>(controller.isLoading, (loading) {
      if (loading || _didAutoOpenSettings) return;
      if (!widget.autoOpenWatermarkSettings) return;
      if (!controller.hasAppWatermark.value) return;
      _didAutoOpenSettings = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_autoStartEditWatermark());
      });
    });
    _readyWorker = ever<bool>(controller.isLoading, (loading) {
      if (loading) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyParsedOverlayIfNeeded();
      });
    });
  }

  void _applyParsedOverlayIfNeeded() {
    final size = _previewSize;
    if (size == null) return;
    controller.applyParsedWatermarkOverlay(size);
  }

  Future<void> _autoStartEditWatermark() async {
    final size = _previewSize;
    final ready = await controller.ensureParsedOverlayReady(size);
    if (!mounted) return;
    if (!ready) {
      _showSnack('解析水印失败，请重试');
      return;
    }
    final opened = await controller.openWatermarkSettings(
      context,
      boardSize: size,
    );
    if (!mounted) return;
    if (!opened) {
      _showSnack('无法打开水印设置');
    }
  }

  @override
  void dispose() {
    _imageTransformController.dispose();
    _loadWorker?.dispose();
    _readyWorker?.dispose();
    if (Get.isRegistered<MediaWatermarkEditorController>(
      tag: widget.asset.id,
    )) {
      Get.delete<MediaWatermarkEditorController>(tag: widget.asset.id);
    }
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onBottomAction(String label) async {
    controller.activeBottomAction.value = label;
    switch (label) {
      case '编辑水印':
        if (!controller.canEditWatermark) {
          _showSnack('当前照片没有可编辑的水印');
          return;
        }
        final edited = await controller.openWatermarkSettings(
          context,
          boardSize: _previewSize,
        );
        if (!mounted) return;
        if (!edited) {
          _showSnack('编辑水印失败，请重试');
        }
      case '加水印':
        if (!controller.canAddWatermark) {
          _showSnack(
            controller.hasWaterMarkOnBoard || controller.hadBakedWatermark
                ? '当前照片已有水印，无法重复添加'
                : '无法添加水印',
          );
          return;
        }
        final added = await controller.openAddWatermark(context);
        if (added && mounted) {
          _showSnack('已添加水印，可拖动调整位置');
        }
      case '加字':
        await controller.openAddTextPicker(context);
      case '去水印':
      case '智能去水印':
        if (!controller.canRemoveWatermark) {
          _showSnack('仅支持去除本应用「水印相机」相册中的水印');
          return;
        }
        final removed = await controller.removeBakedWatermark();
        if (!mounted) return;
        _showSnack(
          removed
              ? '已去除本应用水印'
              : '去水印失败，该照片可能不是本应用水印',
        );
      case '批量加水印':
        context.push(AppPaths.batchAddWatermark);
    }
  }

  Future<void> _save() async {
    var basePath = await controller.resolveBaseMediaPath();
    if (basePath == null || !File(basePath).existsSync()) {
      _showSnack('无法读取文件');
      return;
    }

    controller.isSaving.value = true;
    String savePath = basePath;
    var composed = false;

    if (controller.hasOverlayItems) {
      if (controller.isVideo) {
        controller.isSaving.value = false;
        _showSnack('视频暂不支持叠加合成，请先处理图片');
        return;
      }

      final previewSize = _previewSize;
      if (previewSize == null) {
        controller.isSaving.value = false;
        _showSnack('预览区域未就绪，请稍后重试');
        return;
      }

      _imageTransformController.value = Matrix4.identity();
      controller.clearOverlaySelection();
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      if (!mounted) {
        controller.isSaving.value = false;
        return;
      }

      // 使用逻辑像素截图，与预览坐标 1:1 对齐，避免水印合成后被放大
      final overlayBytes = await _overlayScreenshotController.capture(
        delay: const Duration(milliseconds: 30),
        pixelRatio: 1.0,
      );
      if (overlayBytes == null || overlayBytes.isEmpty) {
        controller.isSaving.value = false;
        _showSnack('叠加层截图失败');
        return;
      }

      final mergedPath = await MediaOverlayCompositor.composeImage(
        imagePath: basePath,
        overlayPngBytes: overlayBytes,
        previewSize: previewSize,
      );
      if (mergedPath == null) {
        controller.isSaving.value = false;
        _showSnack('图片合成失败');
        return;
      }
      savePath = mergedPath;
      composed = true;
    }

    final previewSize = _previewSize;
    final saveMeta = previewSize == null
        ? null
        : controller.buildWatermarkSaveMeta(previewSize);
    final originalId = await controller.resolveOriginalIdForSave();
    final ok = await GallerySaver.savePath(
      savePath,
      isVideo: controller.isVideo,
      album: kWatermarkCameraAlbumName,
      stampTodayDate: !controller.isVideo,
      watermarkData: saveMeta?.data,
      watermarkRect: saveMeta?.rect,
      watermarkBoardSize: saveMeta?.boardSize,
      watermarkOriginalId: originalId,
    );
    controller.isSaving.value = false;
    if (!mounted) return;
    _showSnack(
      ok
          ? composed
              ? controller.isEditingBakedWatermark.value
                  ? '已保存修改后的水印'
                  : '已合成并保存到相册'
              : '已保存到相册'
          : '保存失败',
    );
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  Size? get _previewSize {
    final context = _previewKey.currentContext;
    if (context == null) return null;
    return context.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPreview()),
                _buildBottomBar(),
              ],
            ),
            if (controller.isProcessing.value)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88000000),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 26),
            ),
            const Spacer(),
            Obx(() {
              final saving = controller.isSaving.value;
              return FilledButton(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return KeyedSubtree(
      key: _previewKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (size.width > 0 && size.height > 0) {
              controller.applyParsedWatermarkOverlay(size);
            }
          });
          return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => controller.stackBoardController.select(null),
            behavior: HitTestBehavior.translucent,
            child: Center(child: _buildMediaContent()),
          ),
          Positioned.fill(
            child: Screenshot(
              controller: _overlayScreenshotController,
              child: SizedBox.expand(
                child: StackBoard(
                  keepEdgeAnchoredOnResize: true,
                  pointerEventsThroughEmptyOnly: true,
                  backgroundColor: Colors.transparent,
                  outerGap: 4,
                  controller: controller.stackBoardController,
                ),
              ),
            ),
          ),
        ],
          );
        },
      ),
    );
  }

  Widget _buildMediaContent() {
    if (controller.isVideo) {
      return _VideoPreviewContent(asset: widget.asset);
    }
    return Obx(
      () => _ImagePreviewContent(
        asset: widget.asset,
        transformController: _imageTransformController,
        overridePath: controller.displayImagePath.value,
      ),
    );
  }

  Widget _buildBottomBar() {
    const actions = <_BottomAction>[
      _BottomAction(icon: Icons.title, label: '加字'),
      _BottomAction(icon: Icons.edit_outlined, label: '编辑水印'),
      _BottomAction(icon: Icons.layers_clear_outlined, label: '去水印'),
      _BottomAction(icon: Icons.add_box_outlined, label: '加水印'),
      _BottomAction(icon: Icons.branding_watermark_outlined, label: '批量加水印'),
      _BottomAction(icon: Icons.auto_fix_high_outlined, label: '智能去水印'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.black,
        child: SizedBox(
          height: 88,
          child: Obx(() {
            final active = controller.activeBottomAction.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              itemCount: actions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 2),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _BottomActionButton(
                  action: action,
                  isActive: active == action.label,
                  onTap: () => _onBottomAction(action.label),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _ImagePreviewContent extends StatelessWidget {
  const _ImagePreviewContent({
    required this.asset,
    required this.transformController,
    this.overridePath,
  });

  final AssetEntity asset;
  final TransformationController transformController;
  final String? overridePath;

  @override
  Widget build(BuildContext context) {
    final override = overridePath;
    if (override != null && File(override).existsSync()) {
      return InteractiveViewer(
        transformationController: transformController,
        minScale: 0.5,
        maxScale: 4,
        child: Image.file(File(override), fit: BoxFit.contain),
      );
    }

    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator(color: Colors.white54);
        }
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const Text(
            '无法加载图片',
            style: TextStyle(color: Colors.white70),
          );
        }
        return InteractiveViewer(
          transformationController: transformController,
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(file, fit: BoxFit.contain),
        );
      },
    );
  }
}

class _VideoPreviewContent extends StatelessWidget {
  const _VideoPreviewContent({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(1080, 1920),
        quality: 90,
      ),
      builder: (context, snapshot) {
        final thumb = snapshot.data;
        return Stack(
          alignment: Alignment.center,
          children: [
            if (thumb != null)
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(thumb, fit: BoxFit.contain),
              )
            else
              const Icon(Icons.videocam, size: 80, color: Colors.white54),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ],
        );
      },
    );
  }
}

class _BottomAction {
  const _BottomAction({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.action,
    required this.isActive,
    required this.onTap,
  });

  final _BottomAction action;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: isActive
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
