import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _usernameKey = 'username';
  static final _key = encrypt.Key.fromUtf8('SuperTeclas2024SecretKey32Byte!!');
  static final _iv = encrypt.IV.fromUtf8('1234567890123456');

  static String _encrypt(String plain) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(plain, iv: _iv).base64;
  }

  static String _decrypt(String encrypted) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.decrypt64(encrypted, iv: _iv);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_usernameKey);
    if (stored == null) return null;
    try {
      return _decrypt(stored);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, _encrypt(username));
  }
}
