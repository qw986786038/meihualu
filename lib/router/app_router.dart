import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watermark_camera/pages/CameraPage.dart';
import 'package:watermark_camera/pages/HomePage.dart';
import 'package:watermark_camera/pages/WelcomePage.dart';

import 'app_paths.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppPaths.welcome,
  observers: <NavigatorObserver>[NavigatorObserver()],
  routes: <RouteBase>[
    GoRoute(path: AppPaths.welcome, name: 'welcome', builder: (BuildContext context, GoRouterState state) => const WelcomePage()),
    GoRoute(path: AppPaths.home, name: 'home', builder: (BuildContext context, GoRouterState state) => const HomePage()),
    GoRoute(path: AppPaths.camera, name: 'camera', builder: (BuildContext context, GoRouterState state) => const CameraPage()),
  ],
);
