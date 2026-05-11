import 'package:getx_plus/getx_plus.dart';
import 'contact_logic.dart';

class ContactBinding extends Binding {
  @override
  void dependencies() {
    Get.lazyPut(() => ContactLogic());
  }
}
