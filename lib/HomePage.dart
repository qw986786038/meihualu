import 'package:flutter/material.dart';

import 'CameraPage.dart';
import 'SimpleCameraPage.dart';
import 'StackBoardPage.dart';

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
              Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const CameraPage()));
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('打开相机'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const SimpleCameraPage()));
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('打开相机2'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const StackBoardPage()));
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('打开画板'),
          ),
        ],
      ),
    );
  }
}
