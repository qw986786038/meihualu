import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/services/watermark_removal_service.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class BatchRemoveWatermarkPreviewPage extends StatefulWidget {
  const BatchRemoveWatermarkPreviewPage({super.key, required this.assets});

  final List<AssetEntity> assets;

  @override
  State<BatchRemoveWatermarkPreviewPage> createState() =>
      _BatchRemoveWatermarkPreviewPageState();
}

class _BatchRemoveWatermarkPreviewPageState
    extends State<BatchRemoveWatermarkPreviewPage> {
  bool _isProcessing = true;
  bool _isSaving = false;
  String? _resultPath;
  String? _errorMessage;
  Uint8List? _sourceThumb;

  AssetEntity? get _previewAsset =>
      widget.assets.isEmpty ? null : widget.assets.first;

  int get _count => widget.assets.length;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreview());
  }

  Future<void> _loadPreview() async {
    final asset = _previewAsset;
    if (asset == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '未选择可处理的媒体';
        });
      }
      return;
    }

    final thumb = await asset.thumbnailDataWithSize(
      const ThumbnailSize.square(800),
      quality: 90,
    );
    if (!mounted) return;

    setState(() {
      _sourceThumb = thumb;
      _isProcessing = true;
      _errorMessage = null;
    });

    final canRemove = await WatermarkRemovalService.canRemoveAsset(asset);
    if (!canRemove) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = '仅支持去除本应用「梅花鹿」相册中的水印';
      });
      return;
    }

    final output = await WatermarkRemovalService.removeAppWatermarkFromAsset(
      asset,
    );
    if (!mounted) return;

    if (output == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '预览去水印失败，请重试';
      });
      return;
    }

    setState(() {
      _isProcessing = false;
      _resultPath = output;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmBatchRemove() async {
    if (_count == 0) return;

    setState(() => _isSaving = true);
    var successCount = 0;

    for (final asset in widget.assets) {
      if (!mounted) break;

      final canRemove = await WatermarkRemovalService.canRemoveAsset(asset);
      if (!canRemove) continue;

      final output = await WatermarkRemovalService.removeAppWatermarkFromAsset(
        asset,
      );
      if (output == null) continue;

      final ok = await WatermarkRemovalService.saveResult(
        output,
        isVideo: asset.type == AssetType.video,
      );
      if (ok) successCount++;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (successCount == 0) {
      _showSnack('批量去水印失败，请重试');
      return;
    }

    _showSnack('已成功去除水印 $successCount 张');
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPreview()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 26),
          ),
          const Expanded(
            child: Text(
              '预览',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadPreview,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final asset = _previewAsset;
    if (asset == null) {
      return const Center(child: Text('暂无预览'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            '预览为首张去水印效果，确认后将批量处理所选内容',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: _buildPreviewContent(asset)),
                    if (_sourceThumb != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _buildThumbBox(_sourceThumb!, label: '原图'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(AssetEntity asset) {
    if (asset.type == AssetType.video) {
      final thumb = _sourceThumb;
      return Stack(
        alignment: Alignment.center,
        children: [
          if (thumb != null)
            Image.memory(thumb, fit: BoxFit.contain)
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
    }

    final path = _resultPath;
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }

    if (_sourceThumb != null) {
      return Image.memory(_sourceThumb!, fit: BoxFit.contain);
    }

    return const Text('无法加载预览', style: TextStyle(color: Colors.white70));
  }

  Widget _buildThumbBox(Uint8List bytes, {required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: _isProcessing || _isSaving || _errorMessage != null
              ? null
              : _confirmBatchRemove,
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '确认去水印 ($_count张)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
