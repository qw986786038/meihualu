import 'package:getx_plus/getx_plus.dart';
import 'mine_logic.dart';

class MineBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => MineLogic());
  }
}
