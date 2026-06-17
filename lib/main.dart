import 'package:flutter/material.dart';
import 'package:watermark_camera/router/app_router.dart';
import 'package:watermark_camera/services/aliyun_image_tagging_service.dart';
import 'package:watermark_camera/services/aliyun_ocr_service.dart';
import 'package:watermark_camera/services/amap_location_service.dart';
import 'package:watermark_camera/services/auth_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/photo_sync_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:getx_plus/getx_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(AMapLocationService(), permanent: true);
  Get.put(AliyunImageTaggingService(), permanent: true);
  Get.put(AliyunOcrService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(PhotoSyncService(), permanent: true);
  Get.put(TeamWorkspaceService(), permanent: true);
  Get.put(PersonalSpaceService(), permanent: true);

  runApp(const WatermarkCameraApp());
}

class WatermarkCameraApp extends StatelessWidget {
  const WatermarkCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '水印相机',
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
    );
  }
}
