import 'package:getx_plus/getx_plus.dart';
import 'package:watermark_camera/models/personal_space.dart';
import 'package:watermark_camera/models/team.dart';

enum WorkMode { personal, team }

class AuthService extends GetxService {
  final RxBool isLoggedIn = false.obs;
  final RxString userName = ''.obs;
  final RxString phone = ''.obs;
  final Rx<WorkMode> workMode = WorkMode.personal.obs;
  final Rxn<PersonalSpace> personalSpace = Rxn<PersonalSpace>();
  final RxBool skipLocalSaveAfterSync = false.obs;
  final RxList<Team> teams = <Team>[].obs;
  final Rxn<Team> activeTeam = Rxn<Team>();

  bool get hasPersonalSpace => personalSpace.value != null;
  bool get hasTeam => teams.isNotEmpty;

  bool get uploadToCloud {
    if (workMode.value == WorkMode.personal) {
      return personalSpace.value?.syncEnabled ?? false;
    }
    return true;
  }

  Future<bool> fakeLogin({
    required String phoneNumber,
    String? nickname,
  }) async {
    final trimmedPhone = phoneNumber.trim();
    if (trimmedPhone.isEmpty) return false;

    await Future<void>.delayed(const Duration(milliseconds: 400));

    phone.value = trimmedPhone;
    userName.value = nickname?.trim().isNotEmpty == true
        ? nickname!.trim()
        : '用户${trimmedPhone.substring(trimmedPhone.length - 4)}';
    isLoggedIn.value = true;
    _ensurePersonalSpace();
    return true;
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

  void setWorkMode(WorkMode mode) {
    workMode.value = mode;
  }

  Future<bool> createTeam({
    required String name,
    required String industryType,
    String? brandImagePath,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final team = Team(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      industryType: industryType,
      teamCode: _generateTeamCode(),
      brandImagePath: brandImagePath,
    );
    teams.add(team);
    activeTeam.value = team;
    workMode.value = WorkMode.team;
    return true;
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
    workMode.value = WorkMode.personal;
    personalSpace.value = null;
    skipLocalSaveAfterSync.value = false;
    teams.clear();
    activeTeam.value = null;
  }
}
