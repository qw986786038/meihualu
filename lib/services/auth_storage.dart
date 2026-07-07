import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _tokenKey = 'auth_access_token';
  static const _userIdKey = 'auth_user_id';
  static const _phoneKey = 'auth_phone';

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
