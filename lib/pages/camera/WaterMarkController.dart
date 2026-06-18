import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';

import '../../widgets/WaterMark/WaterMarkWidget.dart';
import '../../widgets/WaterMark/watermark_template_view.dart';
import '../../widgets/stack_board.dart';

class WaterMarkController extends GetxController {
  static const double _cameraWatermarkBottomInset = 210;

  final StackBoardController controller = StackBoardController();
  final RxString selectedTemplateId = kDefaultWatermarkTemplateId.obs;

  final waterMarkTemplate = StackBoardTemplate(
    templateId: 'WaterMark',
    label: 'WaterMark',
    autoSizeToChild: true,
    defaultData: createDefaultWatermarkData(),
    builder: (context, selected, data, updateData) =>
        WaterMarkWidget(data: data, updateData: updateData),
    defaultAllowOverlap: false,
  );

  void _addTemplate(
    StackBoardTemplate template, {
    StackBoardPlacement placement = StackBoardPlacement.topLeft,
    EdgeInsets placementMargin = EdgeInsets.zero,
    bool? allowOverlap,
    bool? draggable,
  }) {
    controller.addFromTemplate(
      template,
      placement: placement,
      placementMargin: placementMargin,
      allowOverlap: allowOverlap,
      draggable: draggable,
    );
  }

  void addWaterMark() {
    final existing = _findWaterMarkItem();
    if (existing != null) {
      _ensureMinimumBottomClearance(_cameraWatermarkBottomInset);
      selectTemplate(selectedTemplateId.value);
      return;
    }
    _addTemplate(
      waterMarkTemplate,
      placement: StackBoardPlacement.bottomLeft,
      placementMargin: const EdgeInsets.only(
        left: 4,
        bottom: _cameraWatermarkBottomInset,
      ),
      allowOverlap: false,
      draggable: true,
    );
    selectTemplate(selectedTemplateId.value);
  }

  void _ensureMinimumBottomClearance(double minBottom) {
    final boardHeight = controller.boardSize.height;
    if (boardHeight <= 0) return;

    final items = controller.items.toList(growable: true);
    final index = items.indexWhere(
      (item) => item.template.templateId == waterMarkTemplate.templateId,
    );
    if (index < 0) return;

    final item = items[index];
    final clearance = boardHeight - item.rect.bottom;
    if (clearance >= minBottom) return;
    // 仅在水印落入底部控件遮挡区时自动上移，避免覆盖用户手动调整的位置。
    if (clearance >= 150) return;

    final nextTop = (item.rect.top - (minBottom - clearance)).clamp(
      0.0,
      double.infinity,
    );
    items[index] = item.copyWith(
      rect: Rect.fromLTWH(
        item.rect.left,
        nextTop,
        item.rect.width,
        item.rect.height,
      ),
    );
    controller.replaceItems(items);
  }

  void removeSelected() {
    controller.removeSelected();
  }

  void selectTemplate(String templateId) {
    final preset = watermarkTemplateById(templateId);
    if (selectedTemplateId.value != preset.id) {
      selectedTemplateId.value = preset.id;
    }
    _updateWaterMarkData((nextData) {
      nextData[kWatermarkDataTemplateId] = preset.id;
    });
  }

  void _updateWaterMarkData(
    void Function(Map<String, dynamic> nextData) updateData,
  ) {
    final items = controller.items.toList(growable: true);
    final index = items.indexWhere(
      (item) => item.template.templateId == waterMarkTemplate.templateId,
    );
    if (index < 0) return;

    final item = items[index];
    final nextData = Map<String, dynamic>.from(item.data);
    updateData(nextData);
    items[index] = item.copyWith(data: nextData);
    controller.replaceItems(items);
  }

  StackBoardItem? _findWaterMarkItem() {
    for (final item in controller.items) {
      if (item.template.templateId == waterMarkTemplate.templateId) {
        return item;
      }
    }
    return null;
  }

  @override
  void onClose() {
    super.onClose();
    controller.dispose();
  }
}
