import 'package:getx_plus/getx_plus.dart';

import '../../widgets/WaterMark/WaterMarkWidget.dart';
import '../../widgets/stack_board.dart';

class WaterMarkController extends GetxController {
  final StackBoardController controller = StackBoardController();

  final waterMarkTemplate = StackBoardTemplate(
    templateId: 'WaterMark',
    label: 'WaterMark',
    autoSizeToChild: true,
    builder: (context, selected, data, updateData) => WaterMarkWidget(data: data, updateData: updateData),
    defaultAllowOverlap: false,
  );

  void _addTemplate(StackBoardTemplate template, {StackBoardPlacement placement = StackBoardPlacement.topLeft, bool? allowOverlap, bool? draggable}) {
    controller.addFromTemplate(template, placement: placement, allowOverlap: allowOverlap, draggable: draggable);
  }

  void addWaterMark() {
    _addTemplate(waterMarkTemplate, placement: StackBoardPlacement.bottomLeft, allowOverlap: false, draggable: true);
  }

  void removeSelected() {
    controller.removeSelected();
  }

  @override
  void onClose() {
    super.onClose();
    controller.dispose();
  }
}
