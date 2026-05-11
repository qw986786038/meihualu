import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// 与各端原生侧一致的 MethodChannel（`processCaptureImage`）。
const MethodChannel _cameraxChannel = MethodChannel('camerax');

/// 一次捕获操作的类型。
enum CameraxCaptureType {
  /// 静态照片。
  photo,

  /// 视频。
  video,
}

/// 当前操作模式。
enum CameraxOperationMode {
  /// 拍照模式。
  photo,

  /// 录像模式。
  video,
}

/// 拍照 / 录像完成后的回调签名。
typedef CameraxCapturedCallback = void Function(
  XFile file,
  CameraxCaptureType type,
);

/// 相机生命周期状态。
enum CameraxStatus {
  /// 未初始化。
  uninitialized,

  /// 正在初始化（获取设备 / 创建底层控制器）。
  initializing,

  /// 初始化完成，预览可用。
  ready,

  /// 出现错误。
  error,

  /// 已释放。
  disposed,
}

/// `camera` 插件的二次封装控制器。
///
/// 通过 [ChangeNotifier] 对外广播状态变更，UI 层只需 `addListener` 或
/// 配合 [AnimatedBuilder] / [ListenableBuilder] 即可响应式刷新。
class CameraxController extends ChangeNotifier {
  CameraxController({
    this.resolutionPreset = ResolutionPreset.high,
    this.enableAudio = true,
    this.imageFormatGroup,
    this.onCaptured,
  });
  static const double _kExposureLimit = 4.0;

  // ---------- 配置 ----------

  /// 分辨率预设。
  final ResolutionPreset resolutionPreset;

  /// 是否启用音频（录像时使用）。
  final bool enableAudio;

  /// 图像格式分组。在使用 [startImageStream] 做扫码 / AI 推理时建议显式指定，
  /// Android 推荐 [ImageFormatGroup.yuv420]，iOS 推荐 [ImageFormatGroup.bgra8888]。
  final ImageFormatGroup? imageFormatGroup;

  /// 拍照或录像成功后的回调，调用方在此自行实现持久化 / 提示等逻辑。
  ///
  /// 插件本身只把 `camera` 输出的临时文件交出来，不负责保存。
  CameraxCapturedCallback? onCaptured;

  // ---------- 内部状态 ----------

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _currentIndex = 0;
  CameraxStatus _status = CameraxStatus.uninitialized;
  String? _errorMessage;
  bool _isTakingPicture = false;
  bool _isRecording = false;
  bool _isStreamingImages = false;
  CameraxOperationMode _operationMode = CameraxOperationMode.photo;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTicker;

  FlashMode _flashMode = FlashMode.auto;
  FocusMode _focusMode = FocusMode.auto;
  ExposureMode _exposureMode = ExposureMode.auto;
  DeviceOrientation? _lockedOrientation;

  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoomLevel = 1;

  double _minExposureOffset = 0;
  double _maxExposureOffset = 0;
  double _exposureOffsetStep = 0;
  double _exposureOffset = 0;
  double? _captureAspectRatio;
  bool _isApplyingExposureOffset = false;
  double? _pendingExposureOffset;

  /// 预览父容器内，相机画面矩形之上的「黑边」高度（逻辑像素）。由 [CameraWidget] 布局同步。
  double _previewLetterboxTop = 0;

  /// 预览父容器内，相机画面矩形之下的「黑边」高度。
  double _previewLetterboxBottom = 0;

  /// 左侧黑边宽度。
  double _previewLetterboxLeft = 0;

  /// 右侧黑边宽度。
  double _previewLetterboxRight = 0;

  // ---------- 基本 getter ----------

  /// 底层 [CameraController]，未初始化时为 null。
  CameraController? get cameraController => _controller;

  /// 当前可用的相机列表。
  List<CameraDescription> get cameras => _cameras;

  /// 当前正在使用的相机描述。
  CameraDescription? get currentCamera =>
      _cameras.isEmpty ? null : _cameras[_currentIndex];

  /// 当前生命周期状态。
  CameraxStatus get status => _status;

  /// 是否已就绪（可显示预览、可拍照）。
  bool get isReady => _status == CameraxStatus.ready;

  /// 错误信息（仅当 [status] == [CameraxStatus.error] 时有值）。
  String? get errorMessage => _errorMessage;

  /// 是否正在拍照。
  bool get isTakingPicture => _isTakingPicture;

  /// 是否正在录像。
  bool get isRecording => _isRecording;

  /// 是否正在向监听者推送图像帧。
  bool get isStreamingImages => _isStreamingImages;

  /// 当前操作模式（拍照/录像）。
  CameraxOperationMode get operationMode => _operationMode;

  /// 当前录像时长。未在录像时为 `Duration.zero`。
  Duration get recordingDuration => _recordingDuration;

  /// 当前闪光灯模式。
  FlashMode get flashMode => _flashMode;

  /// 当前对焦模式（auto / locked）。
  FocusMode get focusMode => _focusMode;

  /// 当前曝光模式（auto / locked）。
  ExposureMode get exposureMode => _exposureMode;

  /// 已锁定的拍摄方向，未锁定时为 null。
  DeviceOrientation? get lockedOrientation => _lockedOrientation;

  /// 最小变焦倍率。
  double get minZoomLevel => _minZoom;

  /// 最大变焦倍率。
  double get maxZoomLevel => _maxZoom;

  /// 当前变焦倍率。
  double get zoomLevel => _zoomLevel;

  /// 曝光补偿最小值（EV）。
  double get minExposureOffset =>
      _minExposureOffset.clamp(-_kExposureLimit, _kExposureLimit).toDouble();

  /// 曝光补偿最大值（EV）。
  double get maxExposureOffset =>
      _maxExposureOffset.clamp(-_kExposureLimit, _kExposureLimit).toDouble();

  /// 曝光补偿步长。`0` 表示连续可调。
  double get exposureOffsetStepSize => _exposureOffsetStep;

  /// 当前曝光补偿值。
  double get exposureOffset => _exposureOffset;

  /// 拍照时按该宽高比中心裁剪，null 表示不额外裁剪。
  double? get captureAspectRatio => _captureAspectRatio;

  /// 当前预览画面上方黑边高度（逻辑像素）。
  ///
  /// 由 [CameraWidget] 在每次预览布局后写入；无黑边（如 cover 全屏）时为 `0`，
  /// 未挂载 [CameraWidget] 或非 [CameraxStatus.ready] 时为 `0`。
  double get previewLetterboxTop => _previewLetterboxTop;

  /// 当前预览画面下方黑边高度。
  double get previewLetterboxBottom => _previewLetterboxBottom;

  /// 当前预览画面左侧黑边宽度。
  double get previewLetterboxLeft => _previewLetterboxLeft;

  /// 当前预览画面右侧黑边宽度。
  double get previewLetterboxRight => _previewLetterboxRight;

  // ---------- 初始化 / 切换 ----------

  /// 初始化相机。会枚举设备并打开默认相机。
  Future<void> initialize() async {
    if (_status == CameraxStatus.initializing) return;
    _setStatus(CameraxStatus.initializing);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorMessage = '未检测到可用相机';
        _setStatus(CameraxStatus.error);
        return;
      }
      await _bindCamera(_cameras[_currentIndex]);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 在所有可用相机中循环切换。
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_currentIndex + 1) % _cameras.length;
    await selectCameraIndex(next);
  }

  /// 在前后摄之间切换。会选择第一个匹配反向 [CameraLensDirection] 的相机。
  Future<void> switchLensDirection() async {
    final cur = currentCamera;
    if (cur == null) return;
    final target = cur.lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final idx = _cameras.indexWhere((c) => c.lensDirection == target);
    if (idx < 0 || idx == _currentIndex) return;
    await selectCameraIndex(idx);
  }

  /// 直接切换到指定 [CameraDescription]。
  Future<void> selectCamera(CameraDescription camera) async {
    final idx = _cameras.indexOf(camera);
    if (idx < 0) return;
    await selectCameraIndex(idx);
  }

  /// 直接切换到 [cameras] 中指定下标的相机。
  Future<void> selectCameraIndex(int index) async {
    if (index < 0 || index >= _cameras.length) return;
    if (index == _currentIndex && _controller != null) return;
    _currentIndex = index;
    _setStatus(CameraxStatus.initializing);
    await _stopImageStreamSilently();
    await _disposeController();
    await _bindCamera(_cameras[_currentIndex]);
  }

  // ---------- 拍照 / 录像 ----------

  /// 拍照，按预览宽高比中心裁剪后返回（见 [_cropPhotoToCaptureAspectRatio]）。
  ///
  /// [isTakingPicture] 仅在底层 [CameraController.takePicture] 期间为 true，
  /// 不包含后续裁剪，避免快门 loading 被后处理拖长。
  Future<XFile?> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (_isTakingPicture) return null;
    _isTakingPicture = true;
    notifyListeners();
    late final XFile file;
    try {
      file = await controller.takePicture();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
      return null;
    } finally {
      _isTakingPicture = false;
      notifyListeners();
    }

    try {
      final cropped = await _cropPhotoToCaptureAspectRatio(file);
      onCaptured?.call(cropped, CameraxCaptureType.photo);
      return cropped;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
      return null;
    }
  }

  /// 同步当前预览框宽高比，用于拍照后按同比例出图。
  void updateCaptureAspectRatio(double? aspectRatio) {
    if (aspectRatio == null || !aspectRatio.isFinite || aspectRatio <= 0) {
      _captureAspectRatio = null;
      return;
    }
    _captureAspectRatio = aspectRatio;
  }

  /// 同步当前预览画面在父容器中的黑边尺寸（逻辑像素）。
  ///
  /// 由 [CameraWidget] 在每次布局后调用，与 [updateCaptureAspectRatio] 同源。
  void updatePreviewLetterbox({
    required Size containerSize,
    required Rect previewRect,
  }) {
    if (!containerSize.width.isFinite ||
        !containerSize.height.isFinite ||
        containerSize.width <= 0 ||
        containerSize.height <= 0) {
      return;
    }

    final top = previewRect.top.clamp(0.0, containerSize.height);
    final bottom =
        (containerSize.height - previewRect.bottom).clamp(0.0, containerSize.height);
    final left = previewRect.left.clamp(0.0, containerSize.width);
    final right =
        (containerSize.width - previewRect.right).clamp(0.0, containerSize.width);

    if (_previewLetterboxTop == top &&
        _previewLetterboxBottom == bottom &&
        _previewLetterboxLeft == left &&
        _previewLetterboxRight == right) {
      return;
    }
    _previewLetterboxTop = top;
    _previewLetterboxBottom = bottom;
    _previewLetterboxLeft = left;
    _previewLetterboxRight = right;
    notifyListeners();
  }

  /// 开始录像。开始前会自动停止图像流（`camera` 限制不可同时启用）。
  Future<void> startVideoRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isRecording) return;
    try {
      if (_isStreamingImages) {
        await _stopImageStreamSilently();
      }
      await controller.startVideoRecording();
      _isRecording = true;
      _operationMode = CameraxOperationMode.video;
      _recordingDuration = Duration.zero;
      _recordingTicker?.cancel();
      _recordingTicker =
          Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 结束录像并返回文件。
  Future<XFile?> stopVideoRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return null;
    try {
      final file = await controller.stopVideoRecording();
      _isRecording = false;
      _recordingTicker?.cancel();
      _recordingTicker = null;
      _recordingDuration = Duration.zero;
      notifyListeners();
      onCaptured?.call(file, CameraxCaptureType.video);
      return file;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
      return null;
    }
  }

  /// 切换操作模式（拍照/录像）。
  void setOperationMode(CameraxOperationMode mode) {
    if (_operationMode == mode) return;
    _operationMode = mode;
    notifyListeners();
  }

  // ---------- 闪光灯 ----------

  /// 设置闪光灯模式：off / auto / always / torch（机型支持才生效）。
  Future<void> setFlashMode(FlashMode mode) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setFlashMode(mode);
      _flashMode = mode;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  // ---------- 对焦 / 测光点 ----------

  /// 设置对焦点。[point] 使用归一化坐标 (0,0) 左上 ~ (1,1) 右下，
  /// 传 null 表示恢复默认（中心 / 自动）。
  Future<void> setFocusPoint(Offset? point) =>
      _applyPoint((c, p) => c.setFocusPoint(p), point);

  /// 设置测光点。坐标定义同 [setFocusPoint]。
  Future<void> setExposurePoint(Offset? point) =>
      _applyPoint((c, p) => c.setExposurePoint(p), point);

  Future<void> _applyPoint(
    Future<void> Function(CameraController c, Offset? p) op,
    Offset? point,
  ) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !isReady) return;
    try {
      await op(controller, point);
      notifyListeners();
    } on CameraException catch (e) {
      if (_isCameraRequestCancellation(e)) return;
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 同时设置对焦与测光点（最常见的「点哪里、就清晰哪里」交互）。
  ///
  /// 成功提交对焦点后会调用 [resetExposureToAuto]，恢复自动曝光与 EV=0；
  /// 因此此前由曝光条 [finalizeManualExposureLock] 锁定的手动补偿会被清除，符合「下次点击对焦才恢复」。
  Future<void> setFocusAndMeteringPoint(Offset? point) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !isReady) return;

    await _safe(() => controller.setFocusMode(FocusMode.auto));
    _focusMode = FocusMode.auto;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        // 串行提交更稳定，避免机型并发取消。
        await controller.setFocusPoint(point);
        await controller.setExposurePoint(point);
        notifyListeners();
        break;
      } on CameraException catch (e) {
        if (!_isCameraRequestCancellation(e)) rethrow;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 24));
          continue;
        }
      }
    }

    // 对焦完成后再恢复自动曝光，避免影响对焦点提交成功率。
    await resetExposureToAuto();
  }

  /// 设置对焦模式（`auto` / `locked`）。
  Future<void> setFocusMode(FocusMode mode) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setFocusMode(mode);
      _focusMode = mode;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 设置曝光模式（`auto` / `locked`）。
  Future<void> setExposureMode(ExposureMode mode) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setExposureMode(mode);
      _exposureMode = mode;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  // ---------- 变焦 ----------

  /// 设置变焦倍率。值会被裁剪到 \[minZoomLevel, maxZoomLevel\]。
  Future<void> setZoomLevel(double zoom) async {
    final controller = _controller;
    if (controller == null) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom).toDouble();
    try {
      await controller.setZoomLevel(clamped);
      _zoomLevel = clamped;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  // ---------- 曝光补偿 ----------

  /// 设置曝光补偿（EV）。值会被裁剪到 \[minExposureOffset, maxExposureOffset\]。
  /// 返回平台真正应用后的值（部分平台会按步长对齐）。
  Future<double?> setExposureOffset(double ev) async {
    final clamped = _clampExposureOffset(ev);
    _pendingExposureOffset = clamped;
    if (_exposureOffset != clamped) {
      // 先更新 UI，让滑杆手感跟手；底层设置异步追赶即可。
      _exposureOffset = clamped;
      notifyListeners();
    }
    if (_isApplyingExposureOffset) {
      // 拖动滑杆时只保留最后一次值，避免并发请求互相取消。
      return clamped;
    }

    try {
      return await _flushPendingExposureOffset();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
      return null;
    }
  }

  /// 手动拖动曝光条 / 曝光补偿结束后调用，确保底层保持 [ExposureMode.locked] 与当前 [exposureOffset]，
  /// 避免机型在松手后仍自动漂移；直到下一次 [setFocusAndMeteringPoint]（点击对焦）触发 [resetExposureToAuto] 才恢复自动测光。
  Future<void> finalizeManualExposureLock() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !isReady) return;
    final ev = _clampExposureOffset(_exposureOffset);
    try {
      await _ensureManualExposureLocked(controller);
      await _safe(() => controller.setExposureOffset(ev));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 重置曝光补偿并切回自动曝光模式。
  ///
  /// 用于点击对焦后恢复系统 AE，避免维持手动曝光导致画面持续偏亮/偏暗。
  Future<void> resetExposureToAuto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !isReady) {
      return;
    }

    final target = _clampExposureOffset(0);
    _pendingExposureOffset = null;
    _exposureOffset = target;
    _exposureMode = ExposureMode.auto;
    notifyListeners();

    // 恢复时并行下发到原生层，减少串行等待造成的体感延迟。
    await Future.wait<void>([
      _safe(() => controller.setExposureMode(ExposureMode.auto)),
      _safe(() => controller.setExposureOffset(target)),
    ]);
  }

  Future<double?> _flushPendingExposureOffset() async {
    _isApplyingExposureOffset = true;
    double? lastApplied;
    try {
      while (_pendingExposureOffset != null) {
        final target = _pendingExposureOffset!;
        _pendingExposureOffset = null;

        final controller = _controller;
        if (controller == null || !controller.value.isInitialized || !isReady) {
          break;
        }

        await _ensureManualExposureLocked(controller);
        try {
          await controller.setExposureOffset(target);
          lastApplied = target;
        } on CameraException catch (e) {
          if (!_isExposureOffsetCancellation(e)) rethrow;
          _pendingExposureOffset ??= target;
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
      return lastApplied ?? _exposureOffset;
    } finally {
      _isApplyingExposureOffset = false;
    }
  }

  Future<void> _ensureManualExposureLocked(CameraController controller) async {
    if (_exposureMode == ExposureMode.locked) return;
    // 手动调曝光时优先锁定 AE，避免画面继续自动漂白/变暗。
    await _safe(() => controller.setExposureMode(ExposureMode.locked));
    _exposureMode = ExposureMode.locked;
  }

  bool _isExposureOffsetCancellation(CameraException e) {
    return e.code == 'setExposureOffsetFailed' && _isCameraRequestCancellation(e);
  }

  bool _isCameraRequestCancellation(CameraException e) {
    final message = (e.description ?? '').toLowerCase();
    return message.contains('canceled') ||
        message.contains('cancelled') ||
        message.contains('camera being closed') ||
        message.contains('new request being submitted');
  }

  double _clampExposureOffset(double ev) =>
      ev.clamp(minExposureOffset, maxExposureOffset).toDouble();

  // ---------- 拍摄方向 / 旋转锁定 ----------

  /// 锁定拍摄方向。不传参数则锁定到当前设备方向。
  Future<void> lockCaptureOrientation([DeviceOrientation? orientation]) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.lockCaptureOrientation(orientation);
      _lockedOrientation = orientation ?? controller.value.deviceOrientation;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 解锁拍摄方向，恢复跟随设备旋转。
  Future<void> unlockCaptureOrientation() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.unlockCaptureOrientation();
      _lockedOrientation = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  // ---------- 图像流（扫码 / AI 推理） ----------

  /// 开启图像流。每一帧都会回调 [onImage]。
  ///
  /// 注意：
  /// - 不能在录像同时启用，会自动忽略。
  /// - 处理函数应尽量轻量（或异步丢帧），否则会出现帧堆积。
  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isStreamingImages || _isRecording) return;
    try {
      await controller.startImageStream(onImage);
      _isStreamingImages = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  /// 关闭图像流。
  Future<void> stopImageStream() async {
    final controller = _controller;
    if (controller == null || !_isStreamingImages) return;
    try {
      await controller.stopImageStream();
      _isStreamingImages = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  Future<void> _stopImageStreamSilently() async {
    if (!_isStreamingImages) return;
    try {
      await _controller?.stopImageStream();
    } catch (_) {
      // 切换 / dispose 时静默失败。
    }
    _isStreamingImages = false;
  }

  // ---------- 预览暂停 / 恢复 ----------

  /// 暂停预览。
  Future<void> pausePreview() async {
    await _controller?.pausePreview();
    notifyListeners();
  }

  /// 恢复预览。
  Future<void> resumePreview() async {
    await _controller?.resumePreview();
    notifyListeners();
  }

  // ---------- 内部 ----------

  Future<void> _bindCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      resolutionPreset,
      enableAudio: enableAudio,
      imageFormatGroup: imageFormatGroup,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await _refreshCapabilities(controller);
      // 沿用上次的闪光灯 / 对焦 / 曝光设置；不支持就忽略。
      await _safe(() => controller.setFlashMode(_flashMode));
      await _safe(() => controller.setFocusMode(_focusMode));
      await _safe(() => controller.setExposureMode(_exposureMode));
      if (_lockedOrientation != null) {
        await _safe(
            () => controller.lockCaptureOrientation(_lockedOrientation));
      }
      _setStatus(CameraxStatus.ready);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(CameraxStatus.error);
    }
  }

  Future<void> _refreshCapabilities(CameraController controller) async {
    Future<double> safe(Future<double> Function() fn, double fallback) async {
      try {
        return await fn();
      } catch (_) {
        return fallback;
      }
    }

    _minZoom = await safe(controller.getMinZoomLevel, 1);
    _maxZoom = await safe(controller.getMaxZoomLevel, 1);
    _zoomLevel = _minZoom;
    final rawMinExposure = await safe(controller.getMinExposureOffset, -4);
    final rawMaxExposure = await safe(controller.getMaxExposureOffset, 4);
    _exposureOffsetStep = await safe(controller.getExposureOffsetStepSize, 0);
    final minExposure = _normalizeCapabilityExposureOffset(rawMinExposure);
    final maxExposure = _normalizeCapabilityExposureOffset(rawMaxExposure);
    _minExposureOffset = minExposure.clamp(-_kExposureLimit, _kExposureLimit);
    _maxExposureOffset = maxExposure.clamp(-_kExposureLimit, _kExposureLimit);
    if (_minExposureOffset >= _maxExposureOffset) {
      _minExposureOffset = -_kExposureLimit;
      _maxExposureOffset = _kExposureLimit;
    }
    _exposureOffset = _clampExposureOffset(0);
  }

  /// 把设备回传的曝光范围统一收敛到本插件约定的 `-4~4 EV`。
  double _normalizeCapabilityExposureOffset(double rawValue) {
    if (rawValue.abs() <= _kExposureLimit + 0.01) return rawValue;
    final step = _exposureOffsetStep;
    if (step > 0) {
      final converted = rawValue * step;
      if (converted.abs() <= _kExposureLimit + 0.01) {
        return converted;
      }
    }
    return rawValue.clamp(-_kExposureLimit, _kExposureLimit).toDouble();
  }

  /// 按 [captureAspectRatio] 对拍照结果做中心裁剪。
  ///
  /// 优先原生 [MethodChannel.processCaptureImage]，失败则回退 [img]。
  Future<XFile> _cropPhotoToCaptureAspectRatio(XFile file) async {
    final targetAspect = _effectiveCaptureAspectRatio;
    if (targetAspect == null || !targetAspect.isFinite || targetAspect <= 0) {
      return file;
    }

    if (!kIsWeb) {
      final outPath = _buildCroppedImagePath(file.path);
      try {
        final ok = await _cameraxChannel.invokeMethod<bool>(
          'processCaptureImage',
          <String, dynamic>{
            'inputPath': file.path,
            'outputPath': outPath,
            'aspectRatio': targetAspect,
            'quality': 95,
          },
        );
        if (ok == true && await File(outPath).exists()) {
          return XFile(outPath);
        }
      } on MissingPluginException {
        // 回退。
      } on PlatformException {
        // 回退。
      } catch (_) {
        // 回退。
      }
    }

    return _cropPhotoToCaptureAspectRatioDart(file, targetAspect);
  }

  Future<XFile> _cropPhotoToCaptureAspectRatioDart(
    XFile file,
    double targetAspect,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;
      final source = img.bakeOrientation(decoded);
      final sourceAspect = source.width / source.height;
      if ((sourceAspect - targetAspect).abs() < 0.01) {
        return file;
      }

      int cropW = source.width;
      int cropH = source.height;
      if (sourceAspect > targetAspect) {
        cropW = (source.height * targetAspect).round();
      } else {
        cropH = (source.width / targetAspect).round();
      }
      if (cropW <= 0 || cropH <= 0) return file;
      final left = ((source.width - cropW) / 2).round();
      final top = ((source.height - cropH) / 2).round();

      final cropped = img.copyCrop(
        source,
        x: left.clamp(0, source.width - 1),
        y: top.clamp(0, source.height - 1),
        width: cropW.clamp(1, source.width),
        height: cropH.clamp(1, source.height),
      );
      final jpg = img.encodeJpg(cropped, quality: 95);
      final outputPath = _buildCroppedImagePath(file.path);
      await File(outputPath).writeAsBytes(jpg, flush: true);
      return XFile(outputPath);
    } catch (_) {
      return file;
    }
  }

  String _buildCroppedImagePath(String sourcePath) {
    final dot = sourcePath.lastIndexOf('.');
    if (dot <= 0) return '${sourcePath}_cropped.jpg';
    final base = sourcePath.substring(0, dot);
    final ext = sourcePath.substring(dot);
    return '${base}_cropped$ext';
  }

  double? get _effectiveCaptureAspectRatio {
    if (_operationMode == CameraxOperationMode.video) {
      return 16 / 9;
    }
    return _captureAspectRatio;
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      // 忽略机型不支持的能力。
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  void _setStatus(CameraxStatus status) {
    _status = status;
    if (status != CameraxStatus.ready) {
      _resetPreviewLetterbox();
    }
    notifyListeners();
  }

  void _resetPreviewLetterbox() {
    if (_previewLetterboxTop == 0 &&
        _previewLetterboxBottom == 0 &&
        _previewLetterboxLeft == 0 &&
        _previewLetterboxRight == 0) {
      return;
    }
    _previewLetterboxTop = 0;
    _previewLetterboxBottom = 0;
    _previewLetterboxLeft = 0;
    _previewLetterboxRight = 0;
  }

  @override
  void dispose() {
    _status = CameraxStatus.disposed;
    _resetPreviewLetterbox();
    _recordingTicker?.cancel();
    _recordingTicker = null;
    unawaited(_releaseAfterDispose());
    super.dispose();
  }

  Future<void> _releaseAfterDispose() async {
    await _stopImageStreamSilently();
    await _disposeController();
  }
}
