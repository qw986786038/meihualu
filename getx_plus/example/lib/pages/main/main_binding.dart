import 'package:getx_plus/getx_plus.dart';
import '../home/home_logic.dart';
import '../contact/contact_logic.dart';
import '../mine/mine_logic.dart';
import 'main_logic.dart';

class MainBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => MainLogic());
    Get.lazyPut(() => HomeLogic());
    Get.lazyPut(() => ContactLogic());
    Get.lazyPut(() => MineLogic());
  }
}
