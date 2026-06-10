import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:watermark_camera/pages/gallery/watermark_template_picker_sheet.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/utils/batch_watermark_helpers.dart';
import 'package:watermark_camera/utils/gallery_saver.dart';
import 'package:watermark_camera/utils/media_overlay_compositor.dart';
import 'package:watermark_camera/utils/watermark_coordinate_formatter.dart';
import 'package:watermark_camera/utils/watermark_eligibility.dart';
import 'package:watermark_camera/utils/watermark_original_store.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_settings_sheet.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

const Color _kPrimaryBlue = Color(0xFF2F7CF6);

class BatchAddWatermarkPreviewPage extends StatefulWidget {
  const BatchAddWatermarkPreviewPage({super.key, required this.assets});

  final List<AssetEntity> assets;

  @override
  State<BatchAddWatermarkPreviewPage> createState() =>
      _BatchAddWatermarkPreviewPageState();
}

class _BatchAddWatermarkPreviewPageState
    extends State<BatchAddWatermarkPreviewPage> {
  final GlobalKey _previewKey = GlobalKey();
  final ScreenshotController _overlayScreenshotController =
      ScreenshotController();
  final StackBoardController _stackBoardController = StackBoardController();
  final Rx<Map<String, dynamic>> _watermarkData =
      Rx<Map<String, dynamic>>(createDefaultWatermarkData());

  PhotoWatermarkContext? _previewContext;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _overlayReady = false;
  late final StackBoardTemplate _waterMarkTemplate;

  List<AssetEntity> get _imageAssets =>
      widget.assets.where((asset) => asset.type == AssetType.image).toList();

  int get _count => _imageAssets.length;

  AssetEntity? get _previewAsset =>
      _imageAssets.isEmpty ? null : _imageAssets.first;

  @override
  void initState() {
    super.initState();
    _waterMarkTemplate = StackBoardTemplate(
      templateId: 'WaterMark',
      label: 'WaterMark',
      autoSizeToChild: true,
      defaultData: _watermarkData.value,
      builder: (context, selected, data, updateData) =>
          _PreviewWatermarkWidget(
        data: data,
        contextInfo: _previewContext,
        onTapSettings: _openWatermarkSettings,
      ),
      defaultAllowOverlap: false,
    );
    unawaited(_loadPreview());
  }

  @override
  void dispose() {
    _stackBoardController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final asset = _previewAsset;
    if (asset == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final contextInfo = await resolvePhotoWatermarkContext(asset);
    if (!mounted) return;

    setState(() {
      _previewContext = contextInfo;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureWatermarkOverlay();
    });
  }

  void _ensureWatermarkOverlay() {
    if (_overlayReady || _findWaterMarkItem() != null) return;
    final size = _previewSize;
    if (size == null || size.width <= 0 || size.height <= 0) return;

    _stackBoardController.setBoardSize(size);
    _stackBoardController.addFromTemplate(
      _waterMarkTemplate,
      placement: StackBoardPlacement.bottomLeft,
      placementMargin: const EdgeInsets.only(left: 8, bottom: 8),
      allowOverlap: false,
      draggable: true,
      data: Map<String, dynamic>.from(_watermarkData.value),
    );
    _overlayReady = true;
  }

  Size? get _previewSize {
    final context = _previewKey.currentContext;
    return context?.size;
  }

  StackBoardItem? _findWaterMarkItem() {
    for (final item in _stackBoardController.items) {
      if (item.template.templateId == _waterMarkTemplate.templateId) {
        return item;
      }
    }
    return null;
  }

  void _updateWatermarkData(Map<String, dynamic> patch) {
    _watermarkData.value = {..._watermarkData.value, ...patch};
    final items = _stackBoardController.items.toList(growable: true);
    final index = items.indexWhere(
      (item) => item.template.templateId == _waterMarkTemplate.templateId,
    );
    if (index >= 0) {
      items[index] = items[index].copyWith(
        data: Map<String, dynamic>.from(_watermarkData.value),
      );
      _stackBoardController.replaceItems(items);
    }
  }

  Future<void> _changeTemplate() async {
    final templateId = await showWatermarkTemplatePickerSheet(context);
    if (templateId == null || !mounted) return;
    _updateWatermarkData({kWatermarkDataTemplateId: templateId});
  }

  Future<void> _openWatermarkSettings() async {
    final locationService = Get.find<AMapLocationService>();
    final templateId = watermarkString(
      _watermarkData.value,
      kWatermarkDataTemplateId,
      fallback: kDefaultWatermarkTemplateId,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return WatermarkSettingsSheet(
          data: _watermarkData.value,
          updateData: _updateWatermarkData,
          templateId: templateId,
          locationService: locationService,
          initialNow: _previewContext?.now ?? DateTime.now(),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmBatchAdd() async {
    if (_count == 0) {
      _showSnack('请选择至少一张图片');
      return;
    }

    final previewSize = _previewSize;
    final watermarkItem = _findWaterMarkItem();
    if (previewSize == null || watermarkItem == null) {
      _showSnack('预览区域未就绪，请稍后重试');
      return;
    }

    setState(() => _isSaving = true);
    _stackBoardController.select(null);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final sharedSettings = Map<String, dynamic>.from(_watermarkData.value);
    final watermarkRect = watermarkItem.rect;

    var successCount = 0;
    for (var i = 0; i < _imageAssets.length; i++) {
      if (!mounted) break;
      final asset = _imageAssets[i];
      final file = await asset.file;
      if (file == null || !file.existsSync()) continue;

      final photoContext = await resolvePhotoWatermarkContext(asset);
      final mergedData = mergeSharedWatermarkSettings(
        sharedSettings,
        photoContext.data,
      );

      final overlayBytes = await _captureOverlayForPhoto(
        previewSize: previewSize,
        data: mergedData,
        photoContext: photoContext,
        watermarkRect: watermarkRect,
      );
      if (overlayBytes == null || overlayBytes.isEmpty) continue;

      final mergedPath = await MediaOverlayCompositor.composeImage(
        imagePath: file.path,
        overlayPngBytes: overlayBytes,
        previewSize: previewSize,
      );
      if (mergedPath == null) continue;

      final originalId = await WatermarkOriginalStore.saveFromPath(file.path);
      final ok = await GallerySaver.savePath(
        mergedPath,
        isVideo: false,
        album: kWatermarkCameraAlbumName,
        stampTodayDate: true,
        watermarkData: mergedData,
        watermarkRect: watermarkRect,
        watermarkBoardSize: previewSize,
        watermarkOriginalId: originalId,
      );
      if (ok) successCount++;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    final skippedVideos = widget.assets.length - _count;
    var message = '已成功添加水印 $successCount 张';
    if (skippedVideos > 0) {
      message += '，已跳过 $skippedVideos 个视频';
    }
    if (successCount == 0) {
      message = '批量加水印失败，请重试';
    }
    _showSnack(message);
    if (successCount > 0) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  Future<Uint8List?> _captureOverlayForPhoto({
    required Size previewSize,
    required Map<String, dynamic> data,
    required PhotoWatermarkContext photoContext,
    required Rect watermarkRect,
  }) async {
    final templateId = watermarkString(
      data,
      kWatermarkDataTemplateId,
      fallback: kDefaultWatermarkTemplateId,
    );

    final overlayWidget = SizedBox(
      width: previewSize.width,
      height: previewSize.height,
      child: Stack(
        children: [
          Positioned(
            left: watermarkRect.left,
            top: watermarkRect.top,
            child: WatermarkTemplateView(
              templateId: templateId,
              now: photoContext.now,
              address: photoContext.address,
              coordinateText: resolvePhotoCoordinateText(data, photoContext.data),
              altitudeText: resolvePhotoAltitudeText(data, photoContext.data),
              showAddress: watermarkBool(
                data,
                kWatermarkDataShowAddress,
                fallback: true,
              ),
              showCoordinate: watermarkBool(
                data,
                kWatermarkDataShowCoordinate,
                fallback: true,
              ),
              showWeekday: watermarkBool(
                data,
                kWatermarkDataShowWeekday,
                fallback: true,
              ),
              showLogo: watermarkBool(
                data,
                kWatermarkDataShowLogo,
                fallback: false,
              ),
              logoPath: watermarkString(data, kWatermarkDataLogoPath),
              showQuickLabel: watermarkBool(
                data,
                kWatermarkDataShowQuickLabel,
                fallback: false,
              ),
              quickLabelText: watermarkString(
                data,
                kWatermarkDataQuickLabelText,
                fallback: '现场拍摄',
              ),
              quickLabelBorderColor: Color(
                watermarkColorInt(
                  data,
                  kWatermarkDataQuickLabelBorderColor,
                  fallback: 0xFFFFC107,
                ),
              ),
              showCustomTitle: watermarkBool(
                data,
                kWatermarkDataShowCustomTitle,
                fallback: false,
              ),
              customTitle: watermarkString(data, kWatermarkDataCustomTitle),
              showAltitude: watermarkBool(
                data,
                kWatermarkDataShowAltitude,
                fallback: false,
              ),
            ),
          ),
        ],
      ),
    );

    return _overlayScreenshotController.captureFromWidget(
      overlayWidget,
      delay: const Duration(milliseconds: 20),
      pixelRatio: 1.0,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_previewAsset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('预览')),
        body: const Center(child: Text('所选内容中没有可处理的图片')),
      );
    }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            '时间、地点等根据具体照片而不同',
            style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: KeyedSubtree(
              key: _previewKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _ensureWatermarkOverlay();
                  });
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(child: _buildPreviewImage()),
                          Positioned.fill(
                            child: StackBoard(
                              keepEdgeAnchoredOnResize: true,
                              pointerEventsThroughEmptyOnly: true,
                              backgroundColor: Colors.transparent,
                              outerGap: 4,
                              controller: _stackBoardController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewImage() {
    final asset = _previewAsset!;
    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator(color: Colors.white54);
        }
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const Text('无法加载图片', style: TextStyle(color: Colors.white70));
        }
        return Image.file(file, fit: BoxFit.contain);
      },
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _changeTemplate,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '换水印',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _confirmBatchAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimaryBlue,
                    minimumSize: const Size(0, 48),
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
                          '确认添加 ($_count张)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewWatermarkWidget extends StatelessWidget {
  const _PreviewWatermarkWidget({
    required this.data,
    required this.contextInfo,
    required this.onTapSettings,
  });

  final Map<String, dynamic> data;
  final PhotoWatermarkContext? contextInfo;
  final VoidCallback onTapSettings;

  String _resolveAddress(AMapLocationService locationService) {
    final selected = watermarkString(data, kWatermarkDataSelectedAddress);
    if (selected.isNotEmpty) return selected;
    if (locationService.watermarkAddress.value.isNotEmpty) {
      return locationService.watermarkAddress.value;
    }
    return '定位中...';
  }

  String? _formatCoordinate(
    Map<String, dynamic> data,
    AMapLocationService locationService,
  ) {
    if (!watermarkBool(data, kWatermarkDataShowCoordinate, fallback: true)) {
      return null;
    }
    final location = locationService.latestLocation.value;
    return WatermarkCoordinateFormatter.format(
      location?.latitude,
      location?.longitude,
      watermarkString(
        data,
        kWatermarkDataCoordinateFormat,
        fallback: kCoordinateFormatDecimal,
      ),
    );
  }

  String? _formatAltitude(
    Map<String, dynamic> data,
    AMapLocationService locationService,
  ) {
    if (!watermarkBool(data, kWatermarkDataShowAltitude, fallback: false)) {
      return null;
    }
    return WatermarkCoordinateFormatter.formatAltitude(
      locationService.latestLocation.value?.altitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Get.find<AMapLocationService>();
    final info = contextInfo;
    final templateId = watermarkString(
      data,
      kWatermarkDataTemplateId,
      fallback: kDefaultWatermarkTemplateId,
    );

    return Obx(() {
      final address = _resolveAddress(locationService);
      final coordinateText = _formatCoordinate(data, locationService);
      final altitudeText = _formatAltitude(data, locationService);

      return GestureDetector(
        onTap: onTapSettings,
        behavior: HitTestBehavior.opaque,
        child: WatermarkTemplateView(
          templateId: templateId,
          now: info?.now ?? DateTime.now(),
          address: address,
          weatherText: _trimToNull(locationService.watermarkWeather.value),
          temperatureText: _trimToNull(locationService.watermarkTemperature.value),
          coordinateText: coordinateText,
          altitudeText: altitudeText,
          showAddress: watermarkBool(data, kWatermarkDataShowAddress, fallback: true),
          showCoordinate: watermarkBool(
            data,
            kWatermarkDataShowCoordinate,
            fallback: true,
          ),
          showWeekday: watermarkBool(
            data,
            kWatermarkDataShowWeekday,
            fallback: true,
          ),
          showLogo: watermarkBool(data, kWatermarkDataShowLogo, fallback: false),
          logoPath: watermarkString(data, kWatermarkDataLogoPath),
          showQuickLabel: watermarkBool(
            data,
            kWatermarkDataShowQuickLabel,
            fallback: false,
          ),
          quickLabelText: watermarkString(
            data,
            kWatermarkDataQuickLabelText,
            fallback: '现场拍摄',
          ),
          quickLabelBorderColor: Color(
            watermarkColorInt(
              data,
              kWatermarkDataQuickLabelBorderColor,
              fallback: 0xFFFFC107,
            ),
          ),
          showCustomTitle: watermarkBool(
            data,
            kWatermarkDataShowCustomTitle,
            fallback: false,
          ),
          customTitle: watermarkString(data, kWatermarkDataCustomTitle),
          showAltitude: watermarkBool(
            data,
            kWatermarkDataShowAltitude,
            fallback: false,
          ),
        ),
      );
    });
  }

  String? _trimToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
