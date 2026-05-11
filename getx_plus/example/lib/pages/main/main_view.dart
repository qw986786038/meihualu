import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import '../contact/contact_view.dart';
import '../home/home_view.dart';
import '../mine/mine_view.dart';
import 'main_logic.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  static const _pages = [HomeView(), ContactView(), MineView()];

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MainLogic>();
    return Obx(
      () => Scaffold(
        body: IndexedStack(index: logic.currentIndex.value, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: logic.currentIndex.value,
          onTap: logic.switchTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.contacts), label: '联系人'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
        ),
      ),
    );
  }
}
