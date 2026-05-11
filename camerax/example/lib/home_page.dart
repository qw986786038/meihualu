import 'dart:async';
import 'dart:io';

import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';

import 'camerax_example_buttons.dart';
import 'camera_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final CameraxController _controller;

  String? _lastPicturePath;
  String? _lastVideoPath;

  @override
  void initState() {
    super.initState();
    _controller = CameraxController(
      resolutionPreset: ResolutionPreset.high,
      enableAudio: true,
    );
    _controller.onCaptured = _handleCaptured;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCaptured(XFile file, CameraxCaptureType type) {
    setState(() {
      switch (type) {
        case CameraxCaptureType.photo:
          _lastPicturePath = file.path;
          break;
        case CameraxCaptureType.video:
          _lastVideoPath = file.path;
          break;
      }
    });
    unawaited(_copyToUserVisibleFolderInBackground(file, type));
  }

  Future<void> _copyToUserVisibleFolderInBackground(
    XFile file,
    CameraxCaptureType type,
  ) async {
    final saved = await _copyToUserVisibleFolder(file, type);
    if (!mounted) return;
    setState(() {
      switch (type) {
        case CameraxCaptureType.photo:
          _lastPicturePath = saved.path;
          break;
        case CameraxCaptureType.video:
          _lastVideoPath = saved.path;
          break;
      }
    });
  }

  Future<XFile> _copyToUserVisibleFolder(
    XFile source,
    CameraxCaptureType type,
  ) async {
    final targetDir = await _resolveUserVisibleDirectory();
    if (targetDir == null) return source;
    try {
      await targetDir.create(recursive: true);
      final ext = _fileExtension(source.path, type);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .replaceAll('.', '');
      final prefix = type == CameraxCaptureType.photo ? 'IMG' : 'VID';
      final targetPath =
          '${targetDir.path}${Platform.pathSeparator}${prefix}_$stamp$ext';
      final copied = await File(source.path).copy(targetPath);
      return XFile(copied.path);
    } catch (_) {
      return source;
    }
  }

  Future<Directory?> _resolveUserVisibleDirectory() async {
    if (Platform.isAndroid) {
      // Android 优先保存到公开图片目录，文件管理器可直接看到。
      final dir = Directory('/storage/emulated/0/Pictures/camerax');
      return dir;
    }
    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        return Directory('$profile${Platform.pathSeparator}Pictures'
            '${Platform.pathSeparator}camerax');
      }
    }
    return null;
  }

  String _fileExtension(String path, CameraxCaptureType type) {
    final dot = path.lastIndexOf('.');
    if (dot > 0 && dot < path.length - 1) return path.substring(dot);
    return type == CameraxCaptureType.photo ? '.jpg' : '.mp4';
  }

  Future<void> _openCamera() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraScreen(controller: _controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('camerax example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('状态: ${_controller.status.name}'),
                      Text('可用相机: ${_controller.cameras.length}'),
                      Text('当前: ${_controller.currentCamera?.name ?? '-'} '
                          '(${_controller.currentCamera?.lensDirection.name ?? '-'})'),
                      Text('闪光灯: ${_controller.flashMode.name}'),
                      Text('变焦: '
                          '${_controller.zoomLevel.toStringAsFixed(2)}x '
                          '(${_controller.minZoomLevel.toStringAsFixed(1)}–${_controller.maxZoomLevel.toStringAsFixed(1)})'),
                      Text('曝光: '
                          '${_controller.exposureOffset.toStringAsFixed(1)} EV '
                          '(${_controller.minExposureOffset.toStringAsFixed(1)}–${_controller.maxExposureOffset.toStringAsFixed(1)})'),
                      if (_lastPicturePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('最近拍照: $_lastPicturePath'),
                        ),
                      if (_lastVideoPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('最近录像: $_lastVideoPath'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HomeOpenCameraButton(
                controller: _controller,
                onPressed: _openCamera,
              ),
              const SizedBox(height: 8),
              HomeEarlyInitializeButton(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}
