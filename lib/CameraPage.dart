import 'dart:io';
import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

import 'CameraWidget.dart';
import 'camera/AppCameraAspectRatioButton.dart';
import 'camera/AppCameraFlashButton.dart';
import 'camera/AppCameraLocationButton.dart';
import 'camera/AppCameraSwitchButton.dart';
import 'camera/AppFilterWidget.dart';
import 'camera/AppZoomSelector.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _textTemplate = StackBoardTemplate(
    templateId: 'text',
    label: 'Text',
    builder: (context, selected, data, updateData) => Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text('Text'),
    ),
    defaultAllowOverlap: false,
  );

  final _buttonTemplate = StackBoardTemplate(
    templateId: 'button',
    label: 'Button',
    defaultData: const {'data': '0'},
    builder: (context, selected, data, updateData) => ElevatedButton(
      onPressed: () {
        int a = int.parse((data['data'] ?? '0').toString());
        a++;
        updateData({'data': '$a'});
      },
      child: Text('Button${data['data']}'),
    ),
    defaultDraggable: true,
  );

  final _boxTemplate = StackBoardTemplate(
    templateId: 'box',
    label: 'Box',
    defaultSize: const Size(140, 72),
    builder: (context, selected, data, updateData) => Container(
      color: const Color(0xFF90CAF9),
      alignment: Alignment.center,
      child: const Text('任意 Widget'),
    ),
  );

  bool _locationWarmedUp = false;

  Future<void> _warmupLocation() async {
    if (_locationWarmedUp) return;
    _locationWarmedUp = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      try {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 3)),
        );
      } catch (_) {
        await Geolocator.getLastKnownPosition();
      }
    } catch (_) {}
  }

  final StackBoardController _controller = StackBoardController();

  void _addFromTemplate(
    StackBoardTemplate template, {
    StackBoardPlacement placement = StackBoardPlacement.topLeft,
    bool? allowOverlap,
    bool? draggable,
  }) {
    _controller.addFromTemplate(
      template,
      placement: placement,
      allowOverlap: allowOverlap,
      draggable: draggable,
    );
  }

  Future<void> _openWatermarkSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      _addFromTemplate(
                        _textTemplate,
                        placement: StackBoardPlacement.topLeft,
                        allowOverlap: false,
                        draggable: true,
                      );
                    },
                    icon: const Icon(Icons.text_fields),
                    label: const Text('左上 Text'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _addFromTemplate(
                        _buttonTemplate,
                        placement: StackBoardPlacement.bottomRight,
                        allowOverlap: true,
                        draggable: true,
                      );
                    },
                    icon: const Icon(Icons.smart_button_outlined),
                    label: const Text('右下 Button'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _addFromTemplate(
                        _boxTemplate,
                        placement: StackBoardPlacement.center,
                        allowOverlap: false,
                        draggable: false,
                      );
                    },
                    icon: const Icon(Icons.crop_square),
                    label: const Text('中间 Box(固定)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _controller.removeSelected();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除选中'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('关闭面板'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_warmupLocation());
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraWidget(
        previewPadding: EdgeInsets.only(top: kToolbarHeight),
        onWatermarkTap: _openWatermarkSheet,
        onBeforeSaveToGallery: (event, paths) async {
          print(paths.length);

          // TODO: 在这里做水印合成/压制，返回“最终要入相册”的文件路径。
          // 例如可把原始 paths 处理成新的输出文件后返回。
          return paths;
        },
        builder: (CameraState state, double previewWidth, double previewHeight) {
          final photoState = state is PhotoCameraState ? state : null;

          return Column(
            children: [
              AppBar(
                // backgroundColor: Colors.transparent,
                actions: [
                  AppCameraFlashButton(state: state),
                  if (photoState != null) AppCameraAspectRatioButton(state: photoState),
                  if (photoState != null) AppCameraLocationButton(state: photoState),
                ],
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: previewWidth,
                height: previewHeight,
                child: StackBoard(
                    keepEdgeAnchoredOnResize: true,
                    pointerEventsThroughEmptyOnly: true,
                    backgroundColor: Colors.transparent,
                    outerGap: 0, controller: _controller),
              ),
            ],
          );
        },
        body: (CameraState state) {
          final photoState = state is PhotoCameraState ? state : null;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppCameraSwitchButton(state: state),
                Container(height: 16, width: 1),
                if (photoState != null && photoState.hasFilters) AppFilterWidget(state: photoState) else if (!kIsWeb && Platform.isAndroid) AppZoomSelector(state: state),
                Container(height: 16, width: 1),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shadowColor: Colors.black54, elevation: 10),
                  onPressed: () {},
                  icon: Icon(Icons.my_location, size: 28),
                ),
                Container(height: 64, width: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}
