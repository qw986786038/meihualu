import 'package:getx_plus/getx_plus.dart';

class MineLogic extends GetxController {
  final userName = '用户'.obs;
  final avatar = ''.obs;

  void logout() {
    userName.value = '用户';
    avatar.value = '';
  }
}
