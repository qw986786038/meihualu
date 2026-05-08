import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

const _galAlbumName = '水印相机';

/// CamerAwesome 先把文件写入临时目录，再用 gal 保存到系统图库。
/// 这样可以兼容拍照/录像并避免直接写图库目录时的系统差异。
Future<Directory> _watermarkStagingDirectory() async {
  return Directory('${Directory.systemTemp.path}/watermark_staging');
}

/// 统一提取拍摄结果中的文件路径（兼容单摄/多摄返回结构）。
List<String> _collectCapturePaths(CaptureRequest request) {
  return request.when(
    single: (s) {
      final p = s.file?.path;
      return p != null ? <String>[p] : <String>[];
    },
    multiple: (m) => [
      for (final f in m.fileBySensor.values)
        if (f?.path != null) f!.path,
    ],
  );
}

/// 把临时文件导出到系统相册指定专辑。
/// Android 与 iOS 都通过 gal 走同一套逻辑。
Future<String?> _exportCaptureFile(String path, {required bool isVideo}) async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return path;
  }
  try {
    // toAlbum=true 代表需要写入自定义相册/专辑的权限。
    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
      return null;
    }
    if (isVideo) {
      await Gal.putVideo(path, album: _galAlbumName);
    } else {
      await Gal.putImage(path, album: _galAlbumName);
    }
    try {
      await File(path).delete();
    } catch (_) {}
    return '系统相册/$_galAlbumName';
  } on GalException {
    return null;
  }
}

/// 拍摄成功后的统一处理：
/// 1) 收集临时文件；2) 导出到相册；3) 给用户反馈结果。
Future<void> _handleCaptureSuccess(BuildContext context, MediaCapture event) async {
  final paths = _collectCapturePaths(event.captureRequest);
  if (paths.isEmpty || !context.mounted) return;
  final isVideo = event.isVideo;
  final exported = <String>[];
  for (final p in paths) {
    final out = await _exportCaptureFile(p, isVideo: isVideo);
    if (out != null) {
      exported.add(out);
    }
  }
  if (!context.mounted) return;
  final msg = exported.isEmpty
      ? (isVideo ? '视频已暂存，未能写入公共相册（请检查存储权限）\n${paths.first}' : '照片已暂存，未能写入公共相册（请检查存储权限）\n${paths.first}')
      : exported.length == 1
      ? (isVideo ? '视频已保存\n${exported.first}' : '照片已保存\n${exported.first}')
      : '已保存 ${exported.length} 个文件到系统相册/$_galAlbumName';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
}

/// 生成照片保存请求：先落地临时目录，成功后再导出到相册。
Future<CaptureRequest> _buildPhotoCapture(List<Sensor> sensors) async {
  final base = await _watermarkStagingDirectory();
  await base.create(recursive: true);
  if (sensors.length == 1) {
    final path = '${base.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return SingleCaptureRequest(path, sensors.first);
  }
  final ts = DateTime.now().millisecondsSinceEpoch;
  return MultipleCaptureRequest({for (final sensor in sensors) sensor: '${base.path}/${sensor.position == SensorPosition.front ? 'front_' : 'back_'}$ts.jpg'});
}

/// 生成视频保存请求：先落地临时目录，成功后再导出到相册。
Future<CaptureRequest> _buildVideoCapture(List<Sensor> sensors) async {
  final base = await _watermarkStagingDirectory();
  await base.create(recursive: true);
  if (sensors.length == 1) {
    final path = '${base.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
    return SingleCaptureRequest(path, sensors.first);
  }
  final ts = DateTime.now().millisecondsSinceEpoch;
  return MultipleCaptureRequest({for (final sensor in sensors) sensor: '${base.path}/${sensor.position == SensorPosition.front ? 'front_' : 'back_'}$ts.mp4'});
}

/// 使用内置 UI：拍照 / 录像切换、快门、切换前后摄等。
class SimpleCameraPage extends StatefulWidget {
  const SimpleCameraPage({super.key});

  @override
  State<SimpleCameraPage> createState() => _SimpleCameraPageState();
}

class _SimpleCameraPageState extends State<SimpleCameraPage> {
  bool _oneXApplied = false;

  /// 设备的最小倍率可能是 0.6x（超广角），这里把默认倍率强制校准到 1.0x。
  Future<void> _applyDefaultOneXZoom() async {
    if (_oneXApplied || !mounted) return;
    for (var i = 0; i < 8 && mounted; i++) {
      final minZoom = await CamerawesomePlugin.getMinZoom();
      final maxZoom = await CamerawesomePlugin.getMaxZoom();
      if (minZoom != null && maxZoom != null && maxZoom > minZoom) {
        final normalized = ((1.0 - minZoom) / (maxZoom - minZoom)).clamp(0.0, 1.0);
        await CamerawesomePlugin.setZoom(normalized);
        _oneXApplied = true;
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 等相机初始化后执行一次 1x 校准；多次 build 由 _oneXApplied 防重。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_applyDefaultOneXZoom());
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraAwesomeBuilder.awesome(
                saveConfig: SaveConfig.photoAndVideo(photoPathBuilder: _buildPhotoCapture, videoPathBuilder: _buildVideoCapture),
                // 先指定后置镜头；1x 会在初始化后按设备倍率区间动态校准。
                sensorConfig: SensorConfig.single(sensor: Sensor.position(SensorPosition.back), flashMode: FlashMode.auto, aspectRatio: CameraAspectRatios.ratio_4_3, zoom: 0.0),
                onMediaCaptureEvent: (MediaCapture event) {
                  if (event.status != MediaCaptureStatus.success) return;
                  if (!context.mounted) return;
                  unawaited(_handleCaptureSuccess(context, event));
                },
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    tooltip: '关闭',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
