import 'package:getx_plus/getx_plus.dart';

class MainLogic extends GetxController {
  final currentIndex = 0.obs;

  void switchTab(int index) => currentIndex.value = index;
}
