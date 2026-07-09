import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/api/api_response.dart';
import 'package:watermark_camera/models/api/login_data.dart';
import 'package:watermark_camera/models/api/space_list_data.dart';
import 'package:watermark_camera/models/api/user_info.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/team.dart';
import 'package:watermark_camera/services/auth_storage.dart';
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
    unawaited(fetchUserInfo());
    unawaited(fetchSpaceList());
  }

  /// 查询个人空间与团队空间列表。
  Future<bool> fetchSpaceList() async {
    final token = accessToken.value.trim();
    if (token.isEmpty) return false;

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<SpaceApiService>().getSpaceList(
        accessToken: token,
      );
      if (!response.isSuccess || response.data == null) {
        lastErrorMessage.value = response.msg ?? '获取空间列表失败';
        return false;
      }

      _applySpaceList(response.data!);
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  void _applySpaceList(SpaceListData data) {
    if (data.userId.isNotEmpty) {
      userId.value = data.userId;
    }

    final personalInfo = data.personalSpace;
    if (personalInfo != null && personalInfo.spaceId.isNotEmpty) {
      final existing = personalSpace.value;
      final syncEnabled = existing?.id == personalInfo.spaceId
          ? (existing?.syncEnabled ?? true)
          : true;
      personalSpace.value = _withPersonalSpaceDisplay(
        personalInfo.toPersonalSpace(
          syncEnabled: syncEnabled,
        ),
      );
    }

    final previousTeams = {for (final team in teams) team.id: team};
    final nextTeams = data.teamSpace
        .where((item) => item.spaceId.isNotEmpty)
        .map((item) {
          final existing = previousTeams[item.spaceId];
          return item.toTeam(
            syncEnabled: existing?.syncEnabled ?? true,
          ).copyWith(
            industryType: existing?.industryType ?? '',
            teamCode: existing?.teamCode ?? '',
          );
        })
        .toList();
    teams.assignAll(nextTeams);

    String? selectedTeamId;
    for (final item in data.teamSpace) {
      if (item.selected && item.spaceId.isNotEmpty) {
        selectedTeamId = item.spaceId;
        break;
      }
    }
    if (selectedTeamId != null) {
      activeTeam.value = _teamById(selectedTeamId);
      workMode.value = WorkMode.team;
    } else {
      final currentId = activeTeam.value?.id;
      activeTeam.value = currentId == null ? null : _teamById(currentId);
      if (activeTeam.value == null && teams.isNotEmpty) {
        activeTeam.value = teams.first;
      }
      if (activeTeam.value == null) {
        workMode.value = WorkMode.personal;
      }
    }

    final active = activeTeam.value;
    if (active != null && Get.isRegistered<TeamWorkspaceService>()) {
      Get.find<TeamWorkspaceService>().ensureTeamInitialized(active, this);
    }
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
    _syncPersonalSpaceDisplay();
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

  void _syncPersonalSpaceDisplay() {
    final space = personalSpace.value;
    if (space == null) return;
    personalSpace.value = _withPersonalSpaceDisplay(space);
  }

  String _resolveNicknameForPersonalSpace() {
    final nick = userInfo.value?.nickName?.trim();
    if (nick != null && nick.isNotEmpty) return nick;

    final name = userName.value.trim();
    if (name.isNotEmpty) return name;

    if (phone.value.length >= 4) {
      return '用户${phone.value.substring(phone.value.length - 4)}';
    }
    return '我';
  }

  PersonalSpace _withPersonalSpaceDisplay(PersonalSpace space) {
    final nickname = _resolveNicknameForPersonalSpace();
    final avatarText = nickname.isNotEmpty ? nickname.substring(0, 1) : '我';
    return space.copyWith(
      name: '$avatarText的个人空间',
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
    unawaited(_persistSession());
    unawaited(fetchUserInfo());
    unawaited(fetchSpaceList());
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

  void setPersonalSyncEnabled(bool enabled) {
    final space = personalSpace.value;
    if (space == null) return;
    personalSpace.value = space.copyWith(syncEnabled: enabled);
  }

  void setTeamSyncEnabled(bool enabled, {String? teamId}) {
    final targetId = teamId ?? activeTeam.value?.id;
    if (targetId == null) return;

    final index = teams.indexWhere((item) => item.id == targetId);
    if (index < 0) return;

    final updated = teams[index].copyWith(syncEnabled: enabled);
    teams[index] = updated;
    if (activeTeam.value?.id == targetId) {
      activeTeam.value = updated;
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
    String? logo,
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
      final response = await Get.find<SpaceApiService>().createTeamSpace(
        accessToken: token,
        name: trimmedName,
        logo: logo?.trim() ?? '',
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '创建团队失败';
        return false;
      }

      final refreshed = await fetchSpaceList();
      if (!refreshed) return false;

      Team? createdTeam;
      for (final team in teams) {
        if (team.name == trimmedName) {
          createdTeam = team;
          break;
        }
      }
      activeTeam.value = createdTeam ?? (teams.isNotEmpty ? teams.last : null);
      if (activeTeam.value != null) {
        workMode.value = WorkMode.team;
        if (Get.isRegistered<TeamWorkspaceService>()) {
          Get.find<TeamWorkspaceService>().ensureTeamInitialized(
            activeTeam.value!,
            this,
          );
        }
      }
      return true;
    } catch (_) {
      if (lastErrorMessage.value.isEmpty) {
        lastErrorMessage.value = '网络异常，请稍后重试';
      }
      return false;
    }
  }

  Future<List<Team>> searchTeamsByName(String keyword) async {
    return _queryTeams(spaceName: keyword);
  }

  Future<List<Team>> searchTeamsByCode(String teamCode) async {
    return _queryTeams(spaceNo: teamCode);
  }

  Future<List<Team>> _queryTeams({
    String? spaceName,
    String? spaceNo,
  }) async {
    final token = accessToken.value.trim();
    if (token.isEmpty) {
      lastErrorMessage.value = '请先登录';
      return const [];
    }

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<SpaceApiService>().queryTeamList(
        accessToken: token,
        spaceName: spaceName?.trim() ?? '',
        spaceNo: spaceNo?.trim() ?? '',
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '查询团队失败';
        return const [];
      }
      return response.rows.map((item) => item.toTeam()).toList();
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return const [];
    }
  }

  Future<bool> joinTeamByCode(String teamCode) async {
    final results = await searchTeamsByCode(teamCode);
    if (results.length != 1) return false;
    return joinTeam(results.first);
  }

  Future<bool> joinTeam(Team team) async {
    final token = accessToken.value.trim();
    if (token.isEmpty) {
      lastErrorMessage.value = '请先登录';
      return false;
    }

    lastErrorMessage.value = '';
    try {
      final response = await Get.find<SpaceApiService>().addTeamMember(
        accessToken: token,
        spaceId: team.id,
      );
      if (!response.isSuccess) {
        lastErrorMessage.value = response.msg ?? '加入团队失败';
        return false;
      }

      final refreshed = await fetchSpaceList();
      if (!refreshed) return false;

      activeTeam.value = _teamById(team.id) ?? (teams.isNotEmpty ? teams.first : null);
      if (activeTeam.value != null) {
        workMode.value = WorkMode.team;
        if (Get.isRegistered<TeamWorkspaceService>()) {
          final workspace = Get.find<TeamWorkspaceService>();
          workspace.ensureTeamInitialized(activeTeam.value!, this);
          unawaited(
            workspace.fetchTeamMembers(
              teamId: activeTeam.value!.id,
              auth: this,
            ),
          );
        }
      }
      return true;
    } catch (_) {
      lastErrorMessage.value = '网络异常，请稍后重试';
      return false;
    }
  }

  Team? _teamById(String teamId) {
    for (final team in teams) {
      if (team.id == teamId) return team;
    }
    return null;
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
