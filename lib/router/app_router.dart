import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/pages/CameraPage.dart';
import 'package:watermark_camera/pages/HomePage.dart';
import 'package:watermark_camera/pages/WelcomePage.dart';
import 'package:watermark_camera/pages/gallery/media_gallery_page.dart';
import 'package:watermark_camera/pages/gallery/ai_remove_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/edit_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/media_multi_select_page.dart';

import 'app_paths.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppPaths.welcome,
  observers: <NavigatorObserver>[NavigatorObserver()],
  routes: <RouteBase>[
    GoRoute(path: AppPaths.welcome, name: 'welcome', builder: (BuildContext context, GoRouterState state) => const WelcomePage()),
    GoRoute(path: AppPaths.home, name: 'home', builder: (BuildContext context, GoRouterState state) => const HomePage()),
    GoRoute(path: AppPaths.camera, name: 'camera', builder: (BuildContext context, GoRouterState state) => const CameraPage()),
    GoRoute(
      path: AppPaths.mediaGallery,
      name: 'mediaGallery',
      builder: (BuildContext context, GoRouterState state) => const MediaGalleryPage(),
    ),
    GoRoute(
      path: AppPaths.mediaMultiSelect,
      name: 'mediaMultiSelect',
      builder: (BuildContext context, GoRouterState state) =>
          const MediaMultiSelectPage(),
    ),
    GoRoute(
      path: AppPaths.aiRemoveWatermark,
      name: 'aiRemoveWatermark',
      builder: (BuildContext context, GoRouterState state) =>
          const AiRemoveWatermarkPickerPage(),
    ),
    GoRoute(
      path: AppPaths.editWatermark,
      name: 'editWatermark',
      builder: (BuildContext context, GoRouterState state) =>
          const EditWatermarkPickerPage(),
    ),
  ],
);
