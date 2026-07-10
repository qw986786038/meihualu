import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_access_token';
  static const _userIdKey = 'auth_user_id';
  static const _phoneKey = 'auth_phone';

  static String _activeTeamKey(String userId) => 'auth_active_team_id_$userId';

  Future<void> saveActiveTeamId({
    required String userId,
    required String teamId,
  }) async {
    final trimmedUserId = userId.trim();
    final trimmedTeamId = teamId.trim();
    if (trimmedUserId.isEmpty || trimmedTeamId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTeamKey(trimmedUserId), trimmedTeamId);
  }

  Future<String?> readActiveTeamId(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeTeamKey(trimmedUserId));
  }

  Future<void> clearActiveTeamId(String userId) async {
    final trimmedUserId = userId.trim();
    if (trimmedUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTeamKey(trimmedUserId));
  }

  Future<void> saveSession({
    required String accessToken,
    required String userId,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_phoneKey, phone);
  }

  Future<({String? token, String? userId, String? phone})> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      token: prefs.getString(_tokenKey),
      userId: prefs.getString(_userIdKey),
      phone: prefs.getString(_phoneKey),
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneKey);
  }
}
