import 'package:getx_plus/getx_plus.dart';
import 'home_logic.dart';

class HomeBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeLogic());
  }
}
