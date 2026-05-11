import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/router/app_paths.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CamerAwesome 示例')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: () {
              context.push(AppPaths.camera);
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('打开相机'),
          ),
        ],
      ),
    );
  }
}
