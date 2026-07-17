import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:watermark_camera/pages/CameraPage.dart';
import 'package:watermark_camera/pages/HomePage.dart';
import 'package:watermark_camera/pages/WelcomePage.dart';
import 'package:watermark_camera/pages/auth/edit_profile_page.dart';
import 'package:watermark_camera/pages/auth/forgot_password_page.dart';
import 'package:watermark_camera/pages/auth/login_page.dart';
import 'package:watermark_camera/pages/auth/wechat_bind_phone_page.dart';
import 'package:watermark_camera/pages/auth/personal_membership_page.dart';
import 'package:watermark_camera/pages/auth/user_profile_page.dart';
import 'package:watermark_camera/pages/personal/personal_space_page.dart';
import 'package:watermark_camera/pages/personal/personal_space_upload_controller.dart';
import 'package:watermark_camera/pages/personal/personal_space_upload_picker_page.dart';
import 'package:watermark_camera/pages/team/create_team_page.dart';
import 'package:watermark_camera/pages/team/join_team_by_code_page.dart';
import 'package:watermark_camera/pages/team/join_team_by_name_page.dart';
import 'package:watermark_camera/pages/team/join_team_page.dart';
import 'package:watermark_camera/pages/team/team_brand_picker_page.dart';
import 'package:watermark_camera/pages/team/team_industry_picker_page.dart';
import 'package:watermark_camera/pages/team/team_department_management_page.dart';
import 'package:watermark_camera/pages/team/team_info_page.dart';
import 'package:watermark_camera/pages/team/team_contact_invite_page.dart';
import 'package:watermark_camera/pages/team/team_invite_members_page.dart';
import 'package:watermark_camera/pages/team/team_membership_page.dart';
import 'package:watermark_camera/pages/team/team_qr_invite_page.dart';
import 'package:watermark_camera/pages/team/team_member_profile_page.dart';
import 'package:watermark_camera/pages/team/team_photo_search_page.dart';
import 'package:watermark_camera/pages/team/team_photo_ledger_page.dart';
import 'package:watermark_camera/pages/team/team_watermark_style_picker_page.dart';
import 'package:watermark_camera/pages/team/team_watermark_template_picker_page.dart';
import 'package:watermark_camera/pages/team/team_workspace_page.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/models/team_member.dart';
import 'package:watermark_camera/pages/gallery/media_gallery_page.dart';
import 'package:watermark_camera/pages/gallery/ai_remove_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_add_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_add_watermark_preview_page.dart';
import 'package:watermark_camera/pages/gallery/batch_remove_watermark_picker_page.dart';
import 'package:watermark_camera/pages/gallery/batch_remove_watermark_preview_page.dart';
import 'package:watermark_camera/pages/gallery/media_verify_picker_page.dart';
import 'package:watermark_camera/pages/camera/image_tagging_picker_page.dart';
import 'package:watermark_camera/pages/camera/screen_text_ocr_picker_page.dart';
import 'package:watermark_camera/pages/settings/sync_settings_page.dart';
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
      path: AppPaths.imageTagging,
      name: 'imageTagging',
      builder: (BuildContext context, GoRouterState state) =>
          const ImageTaggingPickerPage(),
    ),
    GoRoute(
      path: AppPaths.screenTextOcr,
      name: 'screenTextOcr',
      builder: (BuildContext context, GoRouterState state) =>
          const ScreenTextOcrPickerPage(),
    ),
    GoRoute(
      path: AppPaths.syncSettings,
      name: 'syncSettings',
      builder: (BuildContext context, GoRouterState state) =>
          const SyncSettingsPage(),
    ),
    GoRoute(
      path: AppPaths.login,
      name: 'login',
      builder: (BuildContext context, GoRouterState state) =>
          const LoginPage(),
    ),
    GoRoute(
      path: AppPaths.forgotPassword,
      name: 'forgotPassword',
      builder: (BuildContext context, GoRouterState state) =>
          const ForgotPasswordPage(),
    ),
    GoRoute(
      path: AppPaths.wechatBindPhone,
      name: 'wechatBindPhone',
      builder: (BuildContext context, GoRouterState state) {
        final bindToken = state.extra?.toString() ?? '';
        return WechatBindPhonePage(bindToken: bindToken);
      },
    ),
    GoRoute(
      path: AppPaths.userProfile,
      name: 'userProfile',
      builder: (BuildContext context, GoRouterState state) =>
          const UserProfilePage(),
    ),
    GoRoute(
      path: AppPaths.editProfile,
      name: 'editProfile',
      builder: (BuildContext context, GoRouterState state) =>
          const EditProfilePage(),
    ),
    GoRoute(
      path: AppPaths.personalMembership,
      name: 'personalMembership',
      builder: (BuildContext context, GoRouterState state) =>
          const PersonalMembershipPage(),
    ),
    GoRoute(
      path: AppPaths.teamMembership,
      name: 'teamMembership',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra;
        if (extra is TeamMembershipArgs) {
          return TeamMembershipPage(team: extra.team);
        }
        if (extra is Team) {
          return TeamMembershipPage(team: extra);
        }
        return const PersonalMembershipPage(
          planType: '1',
          title: '开通团队会员',
        );
      },
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
        return TeamPhotoSearchPage(spaceId: teamId);
      },
    ),
    GoRoute(
      path: AppPaths.teamPhotoLedger,
      name: 'teamPhotoLedger',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamPhotoLedgerPage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamWatermarkTemplates,
      name: 'teamWatermarkTemplates',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : null;
        return TeamWatermarkTemplatePickerPage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamWatermarkStylePicker,
      name: 'teamWatermarkStylePicker',
      builder: (BuildContext context, GoRouterState state) =>
          const TeamWatermarkStylePickerPage(),
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
      path: AppPaths.teamContactInvite,
      name: 'teamContactInvite',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamContactInvitePage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamQrInvite,
      name: 'teamQrInvite',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamQrInvitePage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamDepartmentManagement,
      name: 'teamDepartmentManagement',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamDepartmentManagementPage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamInfo,
      name: 'teamInfo',
      builder: (BuildContext context, GoRouterState state) {
        final team = state.extra is Team ? state.extra as Team : TeamWorkspacePage.debugTeam;
        return TeamInfoPage(team: team);
      },
    ),
    GoRoute(
      path: AppPaths.teamMemberProfile,
      name: 'teamMemberProfile',
      builder: (BuildContext context, GoRouterState state) {
        if (state.extra is TeamMemberProfileArgs) {
          final args = state.extra as TeamMemberProfileArgs;
          return TeamMemberProfilePage(team: args.team, member: args.member);
        }
        return TeamMemberProfilePage(
          team: TeamWorkspacePage.debugTeam,
          member: TeamMember(
            id: 'unknown',
            name: '成员',
            avatarText: '成',
            isSelf: false,
          ),
        );
      },
    ),
    GoRoute(
      path: AppPaths.teamSpaceUpload,
      name: 'teamSpaceUpload',
      builder: (BuildContext context, GoRouterState state) {
        final spaceId = state.extra is String ? state.extra as String : null;
        return PersonalSpaceUploadPickerPage(spaceId: spaceId);
      },
    ),
    GoRoute(
      path: AppPaths.personalSpace,
      name: 'personalSpace',
      builder: (BuildContext context, GoRouterState state) =>
          const PersonalSpacePage(),
    ),
    GoRoute(
      path: AppPaths.personalSpaceUpload,
      name: 'personalSpaceUpload',
      builder: (BuildContext context, GoRouterState state) {
        final spaceId = state.extra is String ? state.extra as String : null;
        return PersonalSpaceUploadPickerPage(
          spaceId: spaceId,
          mode: PersonalSpacePickerMode.upload,
        );
      },
    ),
    GoRoute(
      path: AppPaths.personalSpaceBatch,
      name: 'personalSpaceBatch',
      builder: (BuildContext context, GoRouterState state) {
        final spaceId = state.extra is String ? state.extra as String : null;
        return PersonalSpaceUploadPickerPage(
          spaceId: spaceId,
          mode: PersonalSpacePickerMode.batch,
        );
      },
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
    GoRoute(
      path: AppPaths.mediaVerify,
      name: 'mediaVerify',
      builder: (BuildContext context, GoRouterState state) =>
          const MediaVerifyPickerPage(),
    ),
  ],
);
