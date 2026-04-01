import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _tokenKey = 'auth_token';

  Future<void> setAuthToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();

    if (token == null) {
      await prefs.remove(_tokenKey);
      return;
    }

    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}