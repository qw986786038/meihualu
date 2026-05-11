import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'home_logic.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HomeLogic>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(
            onPressed: logic.shuffleArticles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: logic.articles.length,
          itemBuilder: (_, index) => ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(logic.articles[index]),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }
}
