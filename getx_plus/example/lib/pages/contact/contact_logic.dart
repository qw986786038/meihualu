import 'package:getx_plus/getx_plus.dart';

class ContactLogic extends GetxController {
  final contacts = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadContacts();
  }

  void _loadContacts() {
    contacts.addAll([
      {'name': '张三', 'phone': '138-0000-0001'},
      {'name': '李四', 'phone': '138-0000-0002'},
      {'name': '王五', 'phone': '138-0000-0003'},
      {'name': '赵六', 'phone': '138-0000-0004'},
    ]);
  }
}
