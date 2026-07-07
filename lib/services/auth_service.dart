import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';

import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/login_data.dart';
import 'package:watermark_camera/models/api/user_info.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/services/auth_storage.dart';
import 'package:watermark_camera/services/file_api_service.dart';
import 'package:watermark_camera/services/personal_space_service.dart';
import 'package:watermark_camera/services/space_api_service.dart';
import 'package:watermark_camera/services/team_workspace_service.dart';
import 'package:watermark_camera/services/user_api_service.dart';

enum WorkMode { personal, team }

class AuthService extends GetxService {
  final AuthStorage _storage = AuthStorage();

  final RxBool isLoggedIn = false.obs;
  final RxString userName = ''.obs;
  final RxString phone = ''.obs;
  final RxString userId = ''.obs;
  final RxString accessToken = ''.obs;
  final RxString lastErrorMessage = ''.obs;
  final Rxn<UserInfo> userInfo = Rxn<UserInfo>();
  final Rx<WorkMode> workMode = WorkMode.personal.obs;
  final Rxn<PersonalSpace> personalSpace = Rxn<PersonalSpace>();
  final RxBool skipLocalSaveAfterSync = false.obs;
  final RxList<Team> teams = <Team>[].obs;
  final Rxn<Team> activeTeam = Rxn<Team>();

  bool get hasPersonalSpace => personalSpace.value != null;
  bool get hasTeam => teams.isNotEmpty;

  bool get shouldSyncToPersonal =>
      isLoggedIn.value && (personalSpace.value?.syncEnabled ?? false);

  bool get shouldSyncToTeam =>
      isLoggedIn.value &&
      activeTeam.value != null &&
      activeTeam.value!.syncEnabled;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    final session = await _storage.readSession();
    final token = session.token?.trim();
    if (token == null || token.isEmpty) return;

    accessToken.value = token;
    userId.value = session.userId ?? '';
    phone.value = session.phone ?? '';
    isLoggedIn.value = true;
    _ensurePersonalSpace();
    unawaited(fetchUserInfo());
  }

  /// 查询当前用户资料。
  Future<bool> fetchUserInfo() async {
    final token = accessToken.value.trim();
    if (token.isEmpty) return false;

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<UserApiService>().getUserInfo(
        accessToken: token,
      );
      if (!response.isSuccess || response.data == null) {
        lastErrorMessage.value = response.msg ?? '获取用户信息失败';
        return false;
      }

      _applyUserInfo(response.data!);
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  void _applyUserInfo(UserInfo info) {
    userInfo.value = info;
    userId.value = info.userId;
    phone.value = info.phone;
    userName.value = info.displayName;
    _syncPersonalSpaceName(info.displayName);
  }

  void updateLocalUserInfo(UserInfo info) {
    _applyUserInfo(info);
  }

  /// 修改个人资料。
  Future<bool> updateUserInfo({
    required String userName,
    required String nickName,
    required String sex,
    required String email,
    String? avatarUrl,
  }) async {
    final token = accessToken.value.trim();
    if (token.isEmpty) return false;

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<UserApiService>().updateUserInfo(
        accessToken: token,
        userName: userName.trim(),
        nickName: nickName.trim(),
        sex: sex.trim(),
        email: email.trim(),
        avatarUrl: avatarUrl?.trim() ?? '',
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '修改资料失败';
        return false;
      }

      await fetchUserInfo();
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  void _syncPersonalSpaceName(String name) {
    final space = personalSpace.value;
    if (space == null) return;
    final avatarText = name.isNotEmpty ? name.substring(0, 1) : '我';
    personalSpace.value = space.copyWith(
      name: '$avatarText的空间',
      avatarText: avatarText,
    );
  }

  Future<void> _persistSession() async {
    await _storage.saveSession(
      accessToken: accessToken.value,
      userId: userId.value,
      phone: phone.value,
    );
  }

  Future<void> _clearSession() async {
    await _storage.clearSession();
  }

  /// 发送短信验证码。
  Future<bool> sendSmsCode({required String phoneNumber}) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty) return false;

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<UserApiService>().sendSmsCode(
        phone: trimmedPhone,
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '验证码发送失败';
        return false;
      }
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  /// 手机号 + 密码登录。
  Future<bool> loginWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty || password.isEmpty) return false;

    return _handleLoginResponse(
      phoneNumber: trimmedPhone,
      responseFuture: Get.find<UserApiService>().loginByPassword(
        phone: trimmedPhone,
        password: password,
      ),
    );
  }

  /// 手机号 + 验证码登录。
  Future<bool> loginWithSmsCode({
    required String phoneNumber,
    required String code,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty || code.trim().isEmpty) return false;

    return _handleLoginResponse(
      phoneNumber: trimmedPhone,
      responseFuture: Get.find<UserApiService>().loginBySmsCode(
        phone: trimmedPhone,
        smsCode: code.trim(),
      ),
    );
  }

  /// 忘记密码，重置密码。
  Future<bool> resetPassword({
    required String phoneNumber,
    required String smsCode,
    required String password,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty ||
        smsCode.trim().isEmpty ||
        password.isEmpty) {
      return false;
    }

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<UserApiService>().updatePassword(
        phone: trimmedPhone,
        smsCode: smsCode.trim(),
        password: password,
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '重置密码失败';
        return false;
      }
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  Future<bool> _handleLoginResponse({
    required String phoneNumber,
    required Future<ApiResponse<LoginData>> responseFuture,
  }) async {
    lastErrorMessage.value = '';
    try {
      final response = await responseFuture;
      if (!response.isSuccess || response.data == null) {
        lastErrorMessage.value = response.msg ?? '登录失败';
        return false;
      }

      final data = response.data!;
      final token = data.accessToken;
      if (token == null || token.isEmpty) {
        lastErrorMessage.value = '登录失败：未返回 token';
        return false;
      }

      return _completeLogin(
        phoneNumber: phoneNumber,
        userId: data.userId ?? '',
        accessToken: token,
        expireIn: data.expireIn,
      );
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  bool _completeLogin({
    required String phoneNumber,
    required String userId,
    required String accessToken,
    int? expireIn,
    String? nickname,
  }) {
    phone.value = phoneNumber;
    this.userId.value = userId;
    this.accessToken.value = accessToken;
    userName.value = nickname?.trim().isNotEmpty == true
        ? nickname!.trim()
        : _resolveDisplayName(
            phoneNumber: phoneNumber,
            accessToken: accessToken,
          );
    isLoggedIn.value = true;
    _ensurePersonalSpace();
    unawaited(_persistSession());
    unawaited(fetchUserInfo());
    return true;
  }

  String _resolveDisplayName({
    required String phoneNumber,
    required String accessToken,
  }) {
    final tokenUserName = _decodeJwtUserName(accessToken);
    if (tokenUserName != null && tokenUserName.isNotEmpty) {
      return tokenUserName;
    }
    return '用户${phoneNumber.substring(phoneNumber.length - 4)}';
  }

  String? _decodeJwtUserName(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is! Map<String, dynamic>) return null;
      return json['userName'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _ensurePersonalSpace() {
    if (personalSpace.value != null) return;

    final name = userName.value;
    final avatarText = name.isNotEmpty ? name.substring(0, 1) : '我';
    personalSpace.value = PersonalSpace(
      id: 'ps_${DateTime.now().millisecondsSinceEpoch}',
      name: '$avatarText的空间',
      avatarText: avatarText,
      syncEnabled: true,
    );
  }

  void setPersonalSyncEnabled(bool enabled) {
    final space = personalSpace.value;
    if (space == null) return;
    personalSpace.value = space.copyWith(syncEnabled: enabled);
  }

  void setTeamSyncEnabled(bool enabled) {
    final team = activeTeam.value;
    if (team == null) return;
    final updated = team.copyWith(syncEnabled: enabled);
    activeTeam.value = updated;
    final index = teams.indexWhere((item) => item.id == team.id);
    if (index >= 0) {
      teams[index] = updated;
    }
  }

  void setWorkMode(WorkMode mode) {
    workMode.value = mode;
  }

  void updateTeam(Team team) {
    final index = teams.indexWhere((item) => item.id == team.id);
    if (index >= 0) {
      teams[index] = team;
    }
    if (activeTeam.value?.id == team.id) {
      activeTeam.value = team;
    }
  }

  void leaveTeam(String teamId) {
    teams.removeWhere((item) => item.id == teamId);
    if (activeTeam.value?.id == teamId) {
      activeTeam.value = teams.isNotEmpty ? teams.first : null;
      if (activeTeam.value == null) {
        workMode.value = WorkMode.personal;
      }
    }
  }

  Future<bool> createTeam({
    required String name,
    required String industryType,
    String? brandImagePath,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final token = accessToken.value.trim();
    if (token.isEmpty) {
      lastErrorMessage.value = '请先登录';
      return false;
    }

    lastErrorMessage.value = '';
    try {
      var logo = '';
      final imagePath = brandImagePath?.trim();
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (file.existsSync()) {
          final uploadResponse = await Get.find<FileApiService>().uploadImage(
            accessToken: token,
            filePath: imagePath,
          );
          if (!uploadResponse.isSuccess ||
              uploadResponse.data == null ||
              uploadResponse.data!.isEmpty) {
            lastErrorMessage.value = uploadResponse.msg ?? '上传logo失败';
            return false;
          }
          logo = uploadResponse.data!;
        }
      }

      final response = await Get.find<SpaceApiService>().createTeamSpace(
        accessToken: token,
        name: trimmedName,
        logo: logo,
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '创建团队失败';
        return false;
      }

      final team = Team(
        id: 'team_${DateTime.now().millisecondsSinceEpoch}',
        name: trimmedName,
        industryType: industryType,
        teamCode: _generateTeamCode(),
        brandImagePath: logo.isNotEmpty ? logo : brandImagePath,
      );
      teams.add(team);
      activeTeam.value = team;
      workMode.value = WorkMode.team;
      if (Get.isRegistered<TeamWorkspaceService>()) {
        Get.find<TeamWorkspaceService>().ensureTeamInitialized(team, this);
      }
      return true;
    } catch (_) {
      if (lastErrorMessage.value.isEmpty) {
        lastErrorMessage.value = '网络异常，请稍后重试';
      }
      return false;
    }
  }

  Future<Team?> findTeamByCode(String teamCode) async {
    final code = teamCode.trim();
    if (code.isEmpty) return null;

    await Future<void>.delayed(const Duration(milliseconds: 400));

    for (final team in kMockJoinableTeams) {
      if (team.teamCode == code) return team;
    }
    return null;
  }

  Future<bool> joinTeamByCode(String teamCode) async {
    final team = await findTeamByCode(teamCode);
    if (team == null) return false;
    return joinTeam(team);
  }

  Future<List<Team>> searchTeamsByName(String keyword) async {
    final query = keyword.trim();
    if (query.length < 3) return const [];

    await Future<void>.delayed(const Duration(milliseconds: 400));

    return kMockJoinableTeams
        .where((team) => team.name.contains(query))
        .toList();
  }

  Future<bool> joinTeam(Team team) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (!teams.any((item) => item.id == team.id)) {
      teams.add(team);
    }
    activeTeam.value = team;
    workMode.value = WorkMode.team;
    if (Get.isRegistered<TeamWorkspaceService>()) {
      Get.find<TeamWorkspaceService>().ensureTeamInitialized(team, this);
    }
    return true;
  }

  String _generateTeamCode() {
    final seed = DateTime.now().millisecondsSinceEpoch % 1000000;
    return seed.toString().padLeft(6, '0');
  }

  void logout() {
    isLoggedIn.value = false;
    userName.value = '';
    phone.value = '';
    userId.value = '';
    accessToken.value = '';
    userInfo.value = null;
    lastErrorMessage.value = '';
    workMode.value = WorkMode.personal;
    personalSpace.value = null;
    skipLocalSaveAfterSync.value = false;
    teams.clear();
    activeTeam.value = null;
    unawaited(_clearSession());
    if (Get.isRegistered<TeamWorkspaceService>()) {
      Get.find<TeamWorkspaceService>().clearAll();
    }
    if (Get.isRegistered<PersonalSpaceService>()) {
      Get.find<PersonalSpaceService>().clearAll();
    }
  }
}
