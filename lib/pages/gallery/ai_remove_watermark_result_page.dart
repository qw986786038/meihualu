import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/services/watermark_removal_service.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class AiRemoveWatermarkResultPage extends StatefulWidget {
  const AiRemoveWatermarkResultPage({super.key, required this.asset});

  final AssetEntity asset;

  bool get isVideo => asset.type == AssetType.video;

  @override
  State<AiRemoveWatermarkResultPage> createState() =>
      _AiRemoveWatermarkResultPageState();
}

class _AiRemoveWatermarkResultPageState extends State<AiRemoveWatermarkResultPage> {
  bool _isProcessing = true;
  bool _isSaving = false;
  String? _resultPath;
  String? _errorMessage;
  Uint8List? _sourceThumb;
  Uint8List? _resultThumb;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSourceThumb());
    unawaited(_startRemoval());
  }

  Future<void> _loadSourceThumb() async {
    final thumb = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize.square(400),
      quality: 85,
    );
    if (!mounted) return;
    setState(() => _sourceThumb = thumb);
  }

  Future<void> _loadResultThumb(String path) async {
    if (widget.isVideo) {
      final thumb = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize.square(400),
        quality: 85,
      );
      if (!mounted) return;
      setState(() => _resultThumb = thumb);
      return;
    }
    final file = File(path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _resultThumb = bytes);
  }

  Future<void> _startRemoval() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _resultPath = null;
      _resultThumb = null;
    });

    final canRemove = await WatermarkRemovalService.canRemoveAsset(widget.asset);
    if (!canRemove) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = '仅支持去除本应用「水印相机」相册中的水印';
      });
      return;
    }

    final file = await widget.asset.file;
    if (file == null || !file.existsSync()) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = widget.isVideo ? '无法读取视频' : '无法读取照片';
      });
      return;
    }

    final output = await WatermarkRemovalService.removeAppWatermarkFromAsset(
      widget.asset,
    );
    if (!mounted) return;

    if (output == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = '去水印失败，请重试';
      });
      return;
    }

    await _loadResultThumb(output);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _resultPath = output;
    });
  }

  Future<void> _saveResult() async {
    final path = _resultPath;
    if (path == null) return;

    setState(() => _isSaving = true);
    final ok = await WatermarkRemovalService.saveResult(
      path,
      isVideo: widget.isVideo,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(ok ? '已保存到相册' : '保存失败')),
      );
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVideo ? 'AI去水印 · 视频' : 'AI去水印'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              widget.isVideo ? '视频去水印处理中...' : 'AI去水印处理中...',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _startRemoval,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_resultPath == null) {
      return const SizedBox.shrink();
    }

    if (widget.isVideo) {
      return _buildVideoPreview();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(_resultPath!), fit: BoxFit.contain),
        ),
        if (_sourceThumb != null) _buildSourceThumbOverlay(),
      ],
    );
  }

  Widget _buildVideoPreview() {
    final thumb = _resultThumb ?? _sourceThumb;
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
        ),
        Positioned(
          bottom: 24,
          child: Text(
            '视频去水印完成，保存后可在相册播放',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
        if (_sourceThumb != null)
          Positioned(
            top: 12,
            left: 12,
            child: _buildThumbBox(_sourceThumb!),
          ),
      ],
    );
  }

  Widget _buildSourceThumbOverlay() {
    final thumb = _sourceThumb;
    if (thumb == null) return const SizedBox.shrink();
    return Positioned(
      top: 12,
      left: 12,
      child: _buildThumbBox(thumb),
    );
  }

  Widget _buildThumbBox(Uint8List bytes) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.black,
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              child: const Text('重选'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _isProcessing || _isSaving || _resultPath == null
                    ? null
                    : _saveResult,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimaryBlue,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('保存到相册'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
