import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _usernameKey = 'username';
  static const _userIdKey = 'user_id';

  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_usernameKey);
      if (stored == null || stored.trim().isEmpty) return null;
      return stored.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUsername(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, username.trim());
    } catch (_) {}
  }

  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_userIdKey);
      if (stored == null || stored.trim().isEmpty) return null;
      return stored.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId.trim());
    } catch (_) {}
  }
}
