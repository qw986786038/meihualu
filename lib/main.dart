import 'package:flutter/material.dart';
import 'package:watermark_camera/pages/camera/CameraController.dart';
import 'package:watermark_camera/router/app_router.dart';
import 'package:getx_plus/getx_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(CameraController());

  runApp(const WatermarkCameraApp());
}

class WatermarkCameraApp extends StatelessWidget {
  const WatermarkCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '水印相机',
      routerConfig: appRouter,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
    );
  }
}
