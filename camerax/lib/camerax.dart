// `camerax` 对外统一导出入口。
// 仅暴露业务常用类型与核心组件：
// - `CameraWidget`：预览与手势容器
// - `CameraxController`：拍照、录像、对焦、曝光控制
export 'package:camera/camera.dart'
    show
        CameraDescription,
        CameraImage,
        CameraLensDirection,
        ResolutionPreset,
        FlashMode,
        FocusMode,
        ExposureMode,
        ImageFormatGroup,
        XFile;
export 'package:flutter/services.dart' show DeviceOrientation;

export 'src/camera_widget.dart';
export 'src/camerax_controller.dart';
