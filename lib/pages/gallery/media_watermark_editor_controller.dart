import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/gallery/add_text_picker_sheet.dart';
import 'package:watermark_camera/pages/gallery/add_text_presets.dart';
import 'package:watermark_camera/pages/gallery/overlay_text_input_dialog.dart';
import 'package:watermark_camera/pages/gallery/overlay_text_item.dart';
import 'package:watermark_camera/pages/gallery/watermark_template_picker_sheet.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/watermark_removal_service.dart';
import 'package:watermark_camera/utils/watermark_eligibility.dart';
import 'package:watermark_camera/utils/watermark_metadata.dart';
import 'package:watermark_camera/utils/watermark_original_store.dart';
import 'package:watermark_camera/widgets/WaterMark/WaterMarkWidget.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_settings_sheet.dart';
import 'package:watermark_camera/widgets/WaterMark/watermark_template_view.dart';
import 'package:watermark_camera/widgets/stack_board.dart';

class MediaWatermarkEditorController extends GetxController {
  MediaWatermarkEditorController({required this.asset});

  final AssetEntity asset;

  final StackBoardController stackBoardController = StackBoardController();
  final Rx<Map<String, dynamic>> watermarkData =
      Rx<Map<String, dynamic>>(createDefaultWatermarkData());
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool hasAppWatermark = false.obs;
  final RxBool watermarkRemoved = false.obs;
  final RxBool showWatermarkOverlay = false.obs;
  final RxnString activeBottomAction = RxnString();
  final RxnString displayImagePath = RxnString();
  final RxnString displayVideoPath = RxnString();
  final Rx<DateTime> now = DateTime.now().obs;

  bool hadBakedWatermark = false;
  final RxBool isEditingBakedWatermark = false.obs;
  WatermarkParsedMeta? _parsedWatermarkMeta;
  String? _originalImageId;
  String? _originalImagePath;
  bool _parsedOverlayApplied = false;

  Timer? _clockTimer;
  late final StackBoardTemplate _waterMarkTemplate;
  late final StackBoardTemplate _textTemplate;

  bool get isVideo => asset.type == AssetType.video;

  bool get hasOverlayItems => stackBoardController.items.isNotEmpty;

  bool get hasWaterMarkOnBoard => _findWaterMarkItem() != null;

  bool get canAddWatermark =>
      (!hadBakedWatermark || watermarkRemoved.value) && !hasWaterMarkOnBoard;

  /// 编辑准备阶段可能已去掉烘焙层并挂上编辑层，此时仍应允许「去水印」。
  bool get canRemoveWatermark =>
      hadBakedWatermark && (hasWaterMarkOnBoard || !watermarkRemoved.value);

  bool get canEditWatermark => hadBakedWatermark || hasWaterMarkOnBoard;

  void clearOverlaySelection() {
    stackBoardController.select(null);
  }

  Future<String?> resolveBaseMediaPath() async {
    if (isVideo) {
      final path = displayVideoPath.value;
      if (path != null) return path;
      return (await asset.file)?.path;
    }
    final path = displayImagePath.value;
    if (path != null) return path;
    return (await asset.file)?.path;
  }

  @override
  void onInit() {
    super.onInit();
    _waterMarkTemplate = StackBoardTemplate(
      templateId: 'WaterMark',
      label: 'WaterMark',
      autoSizeToChild: true,
      defaultData: watermarkData.value,
      builder: (context, selected, data, updateData) => WaterMarkWidget(
        data: data,
        updateData: updateData,
      ),
      defaultAllowOverlap: false,
    );
    _textTemplate = StackBoardTemplate(
      templateId: 'overlayText',
      label: '加字',
      autoSizeToChild: true,
      defaultAllowOverlap: true,
      builder: (context, selected, data, updateData) => OverlayTextItem(
        data: data,
        selected: selected,
        updateData: updateData,
        onDelete: stackBoardController.removeSelected,
      ),
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
    unawaited(_loadEligibility());
  }

  Future<void> _loadEligibility() async {
    isLoading.value = true;
    final ids = await WatermarkEligibility.loadWatermarkAlbumAssetIds();
    hadBakedWatermark = WatermarkEligibility.isEditable(
      asset: asset,
      watermarkAlbumAssetIds: ids,
    );
    hasAppWatermark.value = hadBakedWatermark;
    if (hadBakedWatermark) {
      await prepareBakedWatermarkForEdit();
    }
    isLoading.value = false;
  }

  void ensureWatermarkOverlay({String? templateId}) {
    showWatermarkOverlay.value = true;
    if (_findWaterMarkItem() != null) return;

    final data = Map<String, dynamic>.from(createDefaultWatermarkData());
    if (templateId != null) {
      data[kWatermarkDataTemplateId] = templateId;
    }
    watermarkData.value = data;

    stackBoardController.addFromTemplate(
      _waterMarkTemplate,
      placement: StackBoardPlacement.bottomLeft,
      placementMargin: const EdgeInsets.only(left: 8, bottom: 8),
      allowOverlap: false,
      draggable: true,
      data: data,
    );
  }

  /// 解析元数据 → 去除烘焙水印 → 仅显示可编辑水印层（单层，不叠双水印）。
  Future<bool> prepareBakedWatermarkForEdit() async {
    if (!hadBakedWatermark) return false;
    if (watermarkRemoved.value &&
        _parsedWatermarkMeta != null &&
        isEditingBakedWatermark.value) {
      return true;
    }

    isProcessing.value = true;
    try {
      final sourcePath = (await asset.file)?.path;
      if (sourcePath != null && !isVideo) {
        _parsedWatermarkMeta =
            await WatermarkMetadata.readFromImagePath(sourcePath) ??
            WatermarkMetadata.defaultMeta();
      } else {
        _parsedWatermarkMeta = WatermarkMetadata.defaultMeta();
      }

      if (!watermarkRemoved.value) {
        final applied = await _applyCleanBaseImage();
        if (!applied) return false;
      }

      isEditingBakedWatermark.value = true;
      _parsedOverlayApplied = false;
      return true;
    } finally {
      isProcessing.value = false;
    }
  }

  /// 预览区就绪后，将解析出的水印挂到编辑层（仅一层，可拖动）。
  void applyParsedWatermarkOverlay(Size boardSize) {
    if (_parsedOverlayApplied || !isEditingBakedWatermark.value) return;
    if (hasWaterMarkOnBoard) {
      _parsedOverlayApplied = true;
      return;
    }

    final meta = _parsedWatermarkMeta ?? WatermarkMetadata.defaultMeta();
    watermarkData.value = Map<String, dynamic>.from(meta.data);
    stackBoardController.setBoardSize(boardSize);

    Rect? rect;
    if (meta.layout != null) {
      rect = meta.layout!.toRect(boardSize);
    }

    if (rect != null) {
      stackBoardController.addFromTemplate(
        _waterMarkTemplate,
        initialPosition: Offset(rect.left, rect.top),
        allowOverlap: false,
        draggable: true,
        data: Map<String, dynamic>.from(meta.data),
      );
    } else {
      stackBoardController.addFromTemplate(
        _waterMarkTemplate,
        placement: StackBoardPlacement.bottomLeft,
        placementMargin: const EdgeInsets.only(left: 8, bottom: 8),
        allowOverlap: false,
        draggable: true,
        data: Map<String, dynamic>.from(meta.data),
      );
    }

    showWatermarkOverlay.value = true;
    _parsedOverlayApplied = true;
  }

  Future<bool> ensureParsedOverlayReady(Size? boardSize) async {
    if (!isEditingBakedWatermark.value) return true;
    if (hasWaterMarkOnBoard) return true;
    if (boardSize == null || boardSize.width <= 0 || boardSize.height <= 0) {
      return false;
    }
    applyParsedWatermarkOverlay(boardSize);
    await Future<void>.delayed(Duration.zero);
    return hasWaterMarkOnBoard;
  }

  ({Map<String, dynamic> data, Rect rect, Size boardSize})?
  buildWatermarkSaveMeta(Size boardSize) {
    final item = _findWaterMarkItem();
    if (item == null) return null;
    return (
      data: Map<String, dynamic>.from(watermarkData.value),
      rect: item.rect,
      boardSize: boardSize,
    );
  }

  /// 保存时关联无水印原图 id，供下次编辑直接还原完整底图。
  Future<String?> resolveOriginalIdForSave() async {
    final basePath = await resolveBaseMediaPath();
    if (basePath == null) return _originalImageId;
    if (_originalImagePath == basePath && _originalImageId != null) {
      return _originalImageId;
    }
    return WatermarkOriginalStore.saveFromPath(basePath);
  }

  Future<bool> _applyCleanBaseImage() async {
    final originalPath = await WatermarkOriginalStore.resolvePath(
      _parsedWatermarkMeta?.originalId,
    );
    if (originalPath != null) {
      _originalImageId = _parsedWatermarkMeta?.originalId;
      _originalImagePath = originalPath;
      watermarkRemoved.value = true;
      if (isVideo) {
        displayVideoPath.value = originalPath;
      } else {
        displayImagePath.value = originalPath;
      }
      return true;
    }

    final output = await WatermarkRemovalService.removeAppWatermarkFromAsset(
      asset,
    );
    if (output == null) return false;

    watermarkRemoved.value = true;
    if (isVideo) {
      displayVideoPath.value = output;
    } else {
      displayImagePath.value = output;
    }
    return true;
  }

  Future<bool> openAddWatermark(BuildContext context) async {
    activeBottomAction.value = '加水印';
    if (!canAddWatermark) return false;

    final templateId = await showWatermarkTemplatePickerSheet(context);
    if (templateId == null || !context.mounted) return false;
    ensureWatermarkOverlay(templateId: templateId);
    return true;
  }

  Future<bool> removeBakedWatermark() async {
    if (!canRemoveWatermark) return false;

    isProcessing.value = true;
    try {
      if (_parsedWatermarkMeta == null) {
        final sourcePath = (await asset.file)?.path;
        if (sourcePath != null && !isVideo) {
          _parsedWatermarkMeta =
              await WatermarkMetadata.readFromImagePath(sourcePath);
        }
      }

      final hasCleanBase = isVideo
          ? displayVideoPath.value != null
          : displayImagePath.value != null;

      if (!hasCleanBase) {
        final applied = await _applyCleanBaseImage();
        if (!applied) return false;
      } else {
        watermarkRemoved.value = true;
      }

      _removeWaterMarkFromBoard();
      isEditingBakedWatermark.value = false;
      _parsedOverlayApplied = false;
      activeBottomAction.value = '去水印';
      return true;
    } finally {
      isProcessing.value = false;
    }
  }

  void _removeWaterMarkFromBoard() {
    final items = stackBoardController.items
        .where(
          (item) => item.template.templateId != _waterMarkTemplate.templateId,
        )
        .toList();
    stackBoardController.replaceItems(items);
    if (!hasWaterMarkOnBoard) {
      showWatermarkOverlay.value = items.isNotEmpty;
    }
  }

  void updateWatermarkData(Map<String, dynamic> patch) {
    watermarkData.value = {...watermarkData.value, ...patch};
    _syncWaterMarkItemData();
  }

  void _syncWaterMarkItemData() {
    final items = stackBoardController.items.toList(growable: true);
    final index = items.indexWhere(
      (item) => item.template.templateId == _waterMarkTemplate.templateId,
    );
    if (index < 0) return;
    items[index] = items[index].copyWith(
      data: Map<String, dynamic>.from(watermarkData.value),
    );
    stackBoardController.replaceItems(items);
  }

  StackBoardItem? _findWaterMarkItem() {
    for (final item in stackBoardController.items) {
      if (item.template.templateId == _waterMarkTemplate.templateId) {
        return item;
      }
    }
    return null;
  }

  Future<void> openAddTextPicker(BuildContext context) async {
    activeBottomAction.value = '加字';
    final preset = await showAddTextPickerSheet(context);
    if (preset == null || !context.mounted) return;

    final text = await showOverlayTextInputDialog(
      context,
      initialText: preset.defaultText,
      title: '输入文字',
    );
    if (text == null || text.isEmpty || !context.mounted) return;
    addTextFromPreset(preset, text: text);
  }

  void addTextFromPreset(AddTextPreset preset, {String? text}) {
    stackBoardController.addFromTemplate(
      _textTemplate,
      placement: StackBoardPlacement.center,
      allowOverlap: true,
      draggable: true,
      data: preset.toOverlayData(text: text),
    );
  }

  Future<bool> openWatermarkSettings(
    BuildContext context, {
    Size? boardSize,
  }) async {
    if (!canEditWatermark) return false;
    if (hadBakedWatermark) {
      if (!watermarkRemoved.value) {
        final prepared = await prepareBakedWatermarkForEdit();
        if (!prepared || !context.mounted) return false;
      }
      final ready = await ensureParsedOverlayReady(boardSize);
      if (!ready || !context.mounted) return false;
    } else if (!hasWaterMarkOnBoard) {
      return false;
    }
    activeBottomAction.value = '编辑水印';

    final locationService = Get.find<AMapLocationService>();
    final templateId = watermarkString(
      watermarkData.value,
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
          data: watermarkData.value,
          updateData: updateWatermarkData,
          templateId: templateId,
          locationService: locationService,
          initialNow: now.value,
        );
      },
    );
    return true;
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    stackBoardController.dispose();
    super.onClose();
  }
}
