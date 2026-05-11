import 'package:getx_plus/getx_plus.dart';
import 'bench_logic.dart';

class BenchBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => BenchLogic());
  }
}
