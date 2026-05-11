import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import '../bench/bench_view.dart';
import '../splash/spalsh_view.dart';
import 'mine_logic.dart';

class MineView extends StatelessWidget {
  const MineView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MineLogic>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Obx(
                () => Text(
                  logic.userName.value[0],
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Obx(
              () => Text(
                logic.userName.value,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.speed, color: Colors.deepPurple),
            title: const Text(
              'Obx 性能测试',
              style: TextStyle(color: Colors.deepPurple),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BenchView()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () {
              logic.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashView()),
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
