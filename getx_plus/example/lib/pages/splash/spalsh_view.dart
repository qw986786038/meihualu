import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import '../main/main_view.dart';
import 'splash_logic.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SplashLogic>();
    return Scaffold(
      appBar: AppBar(title: const Text('Splash')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Text(
                'Count: ${logic.count.value}',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainView()),
                );
              },
              child: const Text('进入主页'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: logic.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
