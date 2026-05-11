import 'package:getx_plus/getx_plus.dart';
import 'splash_logic.dart';

class SplashBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashLogic());
  }
}
