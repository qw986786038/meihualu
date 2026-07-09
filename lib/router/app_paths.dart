/// 应用内路径常量（与小程序 query 等对齐时使用同一字符串）。
abstract final class AppPaths {
  /// 底部主导航（ShellRoute + [MainLayout]）
  static const welcome = '/welcome';
  static const home = '/home';
  static const camera = '/camera';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const userProfile = '/user/profile';
  static const editProfile = '/user/profile/edit';
  static const createTeam = '/team/create';
  static const joinTeam = '/team/join';
  static const joinTeamByCode = '/team/join/code';
  static const joinTeamByName = '/team/join/name';
  static const teamIndustryPicker = '/team/industry';
  static const teamBrandPicker = '/team/brand';
  static const teamWorkspace = '/team/workspace';
  static const teamPhotoSearch = '/team/photo-search';
  static const teamPhotoLedger = '/team/photo-ledger';
  static const teamWatermarkTemplates = '/team/watermark-templates';
  static const teamWatermarkStylePicker = '/team/watermark-styles';
  static const teamInviteMembers = '/team/invite-members';
  static const teamContactInvite = '/team/contact-invite';
  static const teamQrInvite = '/team/qr-invite';
  static const teamDepartmentManagement = '/team/department-management';
  static const teamInfo = '/team/info';
  static const teamMemberProfile = '/team/member-profile';
  static const teamSpaceUpload = '/team/upload';
  static const personalSpace = '/personal/space';
  static const personalSpaceUpload = '/personal/upload';
  static const personalSpaceBatch = '/personal/batch';
  static const mediaGallery = '/gallery/media';
  static const mediaMultiSelect = '/gallery/multi-select';
  static const aiRemoveWatermark = '/gallery/ai-remove-watermark';
  static const editWatermark = '/gallery/edit-watermark';
  static const imageTagging = '/camera/image-tagging';
  static const screenTextOcr = '/camera/screen-text-ocr';
  static const syncSettings = '/settings/sync';
  static const batchAddWatermark = '/gallery/batch-add-watermark';
  static const batchAddWatermarkPreview = '/gallery/batch-add-watermark/preview';
  static const batchRemoveWatermark = '/gallery/batch-remove-watermark';
  static const batchRemoveWatermarkPreview =
      '/gallery/batch-remove-watermark/preview';
}
