import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/CameraPage.dart';
import 'package:watermark_camera/pages/HomePage.dart';
import 'package:watermark_camera/pages/WelcomePage.dart';
import 'package:watermark_camera/pages/auth/fake_login_page.dart';
import 'package:watermark_camera/pages/personal/personal_space_page.dart';
import 'package:watermark_camera/pages/team/create_team_page.dart';
import 'package:watermark_camera/pages/team/join_team_by_code_page.dart';
import 'package:watermark_camera/pages/team/join_team_by_name_page.dart';
import 'package:watermark_camera/pages/team/join_team_page.dart';
import 'package:watermark_camera/pages/team/team_brand_picker_page.dart';
import 'package:watermark_camera/pages/team/team_industry_picker_page.dart';
import 'package:watermark_camera/pages/team/team_invite_members_page.dart';
import 'package:watermark_camera/pages/team/team_photo_search_page.dart';
import 'package:watermark_camera/pages/team/team_workspace_page.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/pages/gallery/media_gallery_page.dart';
import 'package:watermark_camera/pages/gallery/ai_remove_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_add_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_add_watermark_preview_page.dart';
import 'package:watermark_camera/pages/gallery/batch_remove_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_remove_watermark_preview_page.dart';
import 'package:watermark_camera/pages/gallery/edit_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/media_multi_select_page.dart';

import 'app_paths.dart';

List<AssetEntity> _readAssetExtra(Object? extra) {
  if (extra is List<AssetEntity>) return extra;
  return const <AssetEntity>[];
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppPaths.welcome,
  observers: <NavigatorObserver>[NavigatorObserver()],
  routes: <RouteBase>[
    GoRoute(path: AppPaths.welcome, name: 'welcome', builder: (BuildContext context, GoRouterState state) => const WelcomePage()),
    GoRoute(path: AppPaths.home, name: 'home', builder: (BuildContext context, GoRouterState state) => const HomePage()),
    GoRoute(path: AppPaths.camera, name: 'camera', builder: (BuildContext context, GoRouterState state) => const CameraPage()),
    GoRoute(
      path: AppPaths.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) =>
          const FakeLoginPage(),
    ),
    GoRoute(
      path: AppPaths.createTeam,
      name: 'createTeam',
      builder: (BuildContext context, GoRouterState state) =>
          const CreateTeamPage(),
    ),
    GoRoute(
      path: AppPaths.joinTeam,
      name: 'joinTeam',
      builder: (BuildContext context, GoRouterState state) =>
          const JoinTeamPage(),
    ),
    GoRoute(
      path: AppPaths.joinTeamByCode,
      name: 'joinTeamByCode',
      builder: (BuildContext context, GoRouterState state) =>
          const JoinTeamByCodePage(),
    ),
    GoRoute(
      path: AppPaths.joinTeamByName,
      name: 'joinTeamByName',
      builder: (BuildContext context, GoRouterState state) =>
          const JoinTeamByNamePage(),
    ),
    GoRoute(
      path: AppPaths.teamIndustryPicker,
      name: 'teamIndustryPicker',
      builder: (BuildContext context, GoRouterState state) {
        final initialSelection = state.extra is String ? state.extra as String : null;
        return TeamIndustryPickerPage(initialSelection: initialSelection);
      },
    ),
    GoRoute(
      path: AppPaths.teamBrandPicker,
      name: 'teamBrandPicker',
      builder: (BuildContext context, GoRouterState state) =>
          const TeamBrandPickerPage(),
    ),
    GoRoute(
      path: AppPaths.teamWorkspace,
      name: 'teamWorkspace',
      builder: (BuildContext context, GoRouterState state) {
        final teamId = state.extra is String ? state.extra as String : null;
        return TeamWorkspacePage(teamId: teamId);
      },
    ),
    GoRoute(
      path: AppPaths.teamPhotoSearch,
      name: 'teamPhotoSearch',
      builder: (BuildContext context, GoRouterState state) {
        final teamId = state.extra is String ? state.extra as String : null;
        return TeamPhotoSearchPage(teamId: teamId);
      },
    ),
    GoRoute(
      path: AppPaths.teamInviteMembers,
      name: 'teamInviteMembers',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamInviteMembersPage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.personalSpace,
      name: 'personalSpace',
      builder: (BuildContext context, GoRouterState state) =>
          const PersonalSpacePage(),
    ),
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
    GoRoute(
      path: AppPaths.batchAddWatermark,
      name: 'batchAddWatermark',
      builder: (BuildContext context, GoRouterState state) =>
          const BatchAddWatermarkPickerPage(),
    ),
    GoRoute(
      path: AppPaths.batchAddWatermarkPreview,
      name: 'batchAddWatermarkPreview',
      builder: (BuildContext context, GoRouterState state) =>
          BatchAddWatermarkPreviewPage(
        assets: _readAssetExtra(state.extra),
      ),
    ),
    GoRoute(
      path: AppPaths.batchRemoveWatermark,
      name: 'batchRemoveWatermark',
      builder: (BuildContext context, GoRouterState state) =>
          const BatchRemoveWatermarkPickerPage(),
    ),
    GoRoute(
      path: AppPaths.batchRemoveWatermarkPreview,
      name: 'batchRemoveWatermarkPreview',
      builder: (BuildContext context, GoRouterState state) =>
          BatchRemoveWatermarkPreviewPage(
        assets: _readAssetExtra(state.extra),
      ),
    ),
  ],
);
