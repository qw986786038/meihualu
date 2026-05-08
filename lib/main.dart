import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import 'HomePage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WatermarkCameraApp());
}

class WatermarkCameraApp extends StatelessWidget {
  const WatermarkCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '水印相机',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: const HomePage(),
    );
  }
}
