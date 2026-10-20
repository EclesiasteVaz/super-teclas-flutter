import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String _read(String key, String fromEnvironmentValue) {
    if (fromEnvironmentValue.isNotEmpty) return fromEnvironmentValue;
    try {
      return dotenv.env[key] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get firebaseApiKey => _read(
        'FIREBASE_API_KEY',
        const String.fromEnvironment('FIREBASE_API_KEY'),
      );

  static String get firebaseAppId => _read(
        'FIREBASE_APP_ID',
        const String.fromEnvironment('FIREBASE_APP_ID'),
      );

  static String get firebaseProjectId => _read(
        'FIREBASE_PROJECT_ID',
        const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      );

  static String get firebaseMessagingSenderId => _read(
        'FIREBASE_MESSAGING_SENDER_ID',
        const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      );

  static String get firebaseStorageBucket => _read(
        'FIREBASE_STORAGE_BUCKET',
        const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      );

  static String get firebaseAuthDomain => _read(
        'FIREBASE_AUTH_DOMAIN',
        const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      );

  static String get firebaseMeasurementId => _read(
        'FIREBASE_MEASUREMENT_ID',
        const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
      );

  static String get apiBaseUrl => _read(
        'API_BASE_URL',
        const String.fromEnvironment('API_BASE_URL'),
      );

  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static Future<void> load() async {
    if (kIsWeb) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
}
