import 'package:flutter/material.dart';
import 'package:getx_plus/getx_plus.dart';
import 'pages/splash/splash_binding.dart';
import 'pages/main/main_binding.dart';
import 'pages/splash/spalsh_view.dart';

void main() {
  Get.runBindings([SplashBinding(), MainBinding()]);
  runApp(const GetxPlusApp());
}

class GetxPlusApp extends StatelessWidget {
  const GetxPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetX Plus Demo',
      showPerformanceOverlay: true,
      home: const SplashView(),
    );
  }
}
