import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _usernameKey = 'username';
  static const _userIdKey = 'user_id';
  static const _sessionIdKey = 'session_id';
  static const _highScoreKey = 'high_score';

  static String _generateLocalSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      8,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
    return 'sess_${timestamp}_$randomPart';
  }

  static Future<String> getOrCreateSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSession = prefs.getString(_sessionIdKey)?.trim();
      if (existingSession != null &&
          existingSession.isNotEmpty &&
          existingSession != 'anonymous') {
        return existingSession;
      }

      final existingUser = prefs.getString(_userIdKey)?.trim();
      if (existingUser != null &&
          existingUser.isNotEmpty &&
          existingUser != 'anonymous') {
        await prefs.setString(_sessionIdKey, existingUser);
        return existingUser;
      }

      final generated = _generateLocalSessionId();
      await prefs.setString(_sessionIdKey, generated);
      await prefs.setString(_userIdKey, generated);
      return generated;
    } catch (_) {
      return _generateLocalSessionId();
    }
  }

  static Future<String?> getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_sessionIdKey)?.trim();
      if (stored == null || stored.isEmpty || stored == 'anonymous') {
        return null;
      }
      return stored;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSessionId(String sessionId) async {
    final trimmed = sessionId.trim();
    if (trimmed.isEmpty || trimmed == 'anonymous') return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionIdKey, trimmed);
    } catch (_) {}
  }

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
    final trimmed = username.trim();
    if (trimmed.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usernameKey, trimmed);
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
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, trimmed);
      final currentSession = prefs.getString(_sessionIdKey)?.trim();
      if ((currentSession == null ||
              currentSession.isEmpty ||
              currentSession == 'anonymous') &&
          trimmed != 'anonymous') {
        await prefs.setString(_sessionIdKey, trimmed);
      }
    } catch (_) {}
  }

  static Future<int> getHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_highScoreKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveHighScore(int score) async {
    if (score <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_highScoreKey) ?? 0;
      if (score > current) {
        await prefs.setInt(_highScoreKey, score);
      }
    } catch (_) {}
  }
}
