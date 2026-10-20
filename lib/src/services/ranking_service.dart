import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:super_teclas/src/config/env.dart';
import 'package:super_teclas/src/data/models/game_session_model.dart';
import 'package:super_teclas/src/services/storage_service.dart';

class RankingEntry {
  final String username;
  final int score;
  final int wordsCompleted;
  final double accuracy;
  final double averageSpeed;
  final DateTime createdAt;

  RankingEntry({
    required this.username,
    required this.score,
    required this.wordsCompleted,
    required this.accuracy,
    required this.averageSpeed,
    required this.createdAt,
  });

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['created_at'] ?? map['createdAt'];
    DateTime parsedDate;
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return RankingEntry(
      username: (map['username'] as String?) ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      wordsCompleted:
          ((map['words_completed'] ?? map['wordsCompleted']) as num?)?.toInt() ??
              0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      averageSpeed:
          ((map['average_speed'] ?? map['averageSpeed']) as num?)?.toDouble() ??
              0.0,
      createdAt: parsedDate,
    );
  }
}

class RankingService {
  static const _rankingsCollection = 'rankings';
  static const _gamesCollection = 'games';
  static const _maxRetrieved = 20;

  static Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      customActionHandler;
  static Stream<Map<String, dynamic>> Function(String gameId)?
      customSnapshotStreamFactory;

  static bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool get isServerAuthoritativeAvailable {
    if (customActionHandler != null) return true;
    return isAvailable && Env.apiBaseUrl.trim().isNotEmpty;
  }

  static Future<String> ensureAuthenticatedUser() async {
    if (!isAvailable) {
      final cached = await StorageService.getUserId();
      return cached ?? 'anonymous';
    }

    try {
      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;
      if (user == null) {
        final credential = await auth.signInAnonymously();
        user = credential.user;
      }
      final uid = user?.uid ?? 'anonymous';
      await StorageService.saveUserId(uid);
      return uid;
    } catch (e) {
      debugPrint('[RankingService] Auth error: $e');
      final cached = await StorageService.getUserId();
      return cached ?? 'anonymous';
    }
  }

  static Future<String?> _getIdToken() async {
    if (!isAvailable) return null;
    try {
      await ensureAuthenticatedUser();
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _postGameAction(
    Map<String, dynamic> payload,
  ) async {
    if (customActionHandler != null) {
      return await customActionHandler!(payload);
    }

    final baseUrl = Env.apiBaseUrl.trim();
    if (!isAvailable || baseUrl.isEmpty) return null;

    try {
      final idToken = await _getIdToken();
      final uri = Uri.parse(
        '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/game-session',
      );
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null && idToken.isNotEmpty)
                'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              ...payload,
              if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('[RankingService] Game action error: $e');
      return null;
    }
  }

  static Future<ServerGameStepResult?> startServerGameSession({
    required String languageCode,
    String? username,
  }) async {
    if (!isServerAuthoritativeAvailable) return null;

    try {
      final resolvedUsername =
          username ?? (await StorageService.getUsername()) ?? '';
      final response = await _postGameAction({
        'action': 'start',
        'languageCode': languageCode == 'en' ? 'en' : 'pt',
        'username': resolvedUsername,
      });
      if (response == null || response['gameId'] == null) return null;
      return ServerGameStepResult.fromMap(
        response,
        defaultLanguage: languageCode,
      );
    } catch (e) {
      debugPrint('[RankingService] Start server game session error: $e');
      return null;
    }
  }

  static Future<String?> startGameSession({
    required String languageCode,
    String? username,
  }) async {
    final result = await startServerGameSession(
      languageCode: languageCode,
      username: username,
    );
    return result?.gameId;
  }

  static Future<ServerGameStepResult?> submitWordToServer({
    required String gameId,
    required String word,
    double? accuracy,
    String languageCode = 'pt',
  }) async {
    if (!isServerAuthoritativeAvailable || gameId.isEmpty) return null;

    final response = await _postGameAction({
      'action': 'submit',
      'gameId': gameId,
      'word': word.trim(),
      if (accuracy != null) 'accuracy': accuracy,
    });
    if (response == null) return null;
    return ServerGameStepResult.fromMap(
      response,
      defaultLanguage: languageCode,
    );
  }

  static Future<ServerGameStepResult?> pauseGameOnServer({
    required String gameId,
    String languageCode = 'pt',
  }) async {
    if (!isServerAuthoritativeAvailable || gameId.isEmpty) return null;

    final response = await _postGameAction({
      'action': 'pause',
      'gameId': gameId,
    });
    if (response == null) return null;
    return ServerGameStepResult.fromMap(
      response,
      defaultLanguage: languageCode,
    );
  }

  static Future<ServerGameStepResult?> resumeGameOnServer({
    required String gameId,
    String languageCode = 'pt',
  }) async {
    if (!isServerAuthoritativeAvailable || gameId.isEmpty) return null;

    final response = await _postGameAction({
      'action': 'resume',
      'gameId': gameId,
    });
    if (response == null) return null;
    return ServerGameStepResult.fromMap(
      response,
      defaultLanguage: languageCode,
    );
  }

  static Future<ServerGameStepResult?> timeoutGameOnServer({
    required String gameId,
    int? wordSequence,
    double? accuracy,
    String reason = 'client_timer_expired',
    String languageCode = 'pt',
  }) async {
    if (!isServerAuthoritativeAvailable || gameId.isEmpty) return null;

    final response = await _postGameAction({
      'action': 'timeout',
      'gameId': gameId,
      'reason': reason,
      if (wordSequence != null) 'wordSequence': wordSequence,
      if (accuracy != null) 'accuracy': accuracy,
    });
    if (response == null) return null;
    return ServerGameStepResult.fromMap(
      response,
      defaultLanguage: languageCode,
    );
  }

  static Stream<ServerGameStepResult>? watchGameSession({
    required String gameId,
    String languageCode = 'pt',
  }) {
    if (gameId.isEmpty || gameId.startsWith('local_')) return null;

    if (customSnapshotStreamFactory != null) {
      return customSnapshotStreamFactory!(gameId).map(
        (data) => ServerGameStepResult.fromMap(
          data,
          defaultLanguage: languageCode,
        ),
      );
    }

    if (!isAvailable) return null;

    try {
      return FirebaseFirestore.instance
          .collection(_gamesCollection)
          .doc(gameId)
          .snapshots()
          .where((snap) => snap.exists && snap.data() != null)
          .map(
            (snap) => ServerGameStepResult.fromMap(
              snap.data()!,
              defaultLanguage: languageCode,
            ),
          );
    } catch (_) {
      return null;
    }
  }

  static Future<void> syncGameSessionState({
    required String gameId,
    required GameStatus status,
    required int pauseCount,
    required int totalPausedDurationMs,
    required int wordsCompleted,
    required int score,
  }) async {
    if (!isServerAuthoritativeAvailable || gameId.isEmpty) return;

    if (status == GameStatus.paused) {
      await pauseGameOnServer(gameId: gameId);
    } else if (status == GameStatus.running) {
      await resumeGameOnServer(gameId: gameId);
    } else if (status == GameStatus.finished) {
      await timeoutGameOnServer(gameId: gameId);
    }
  }

  static Future<void> submitScore({
    required String username,
    required int score,
    required int wordsCompleted,
    required double accuracy,
    double averageSpeed = 0,
    GameSessionModel? session,
  }) async {
    if (!isAvailable && customActionHandler == null) {
      debugPrint('[RankingService] Firebase client not available');
      return;
    }

    if (session != null) {
      final localValidation = GameSessionModel.validateSession(
        session,
        enforceBiomechanicalLimit: false,
      );
      if (!localValidation.isValid) {
        debugPrint(
          '[RankingService] Local session validation rejected: '
          '${localValidation.rejectionReason}',
        );
        return;
      }
    }

    try {
      final targetGameId = session?.gameId;
      if (targetGameId == null ||
          targetGameId.isEmpty ||
          targetGameId.startsWith('local_')) {
        return;
      }

      if (customActionHandler != null) {
        await customActionHandler!({
          'action': 'validate',
          'gameId': targetGameId,
          'username': username,
          'accuracy': accuracy,
        });
        return;
      }

      if (Env.apiBaseUrl.isNotEmpty) {
        final idToken = await _getIdToken();
        final uri = Uri.parse(
          '${Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/validate-game',
        );
        await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (idToken != null && idToken.isNotEmpty)
                  'Authorization': 'Bearer $idToken',
              },
              body: jsonEncode({
                'gameId': targetGameId,
                'username': username,
                'accuracy': accuracy,
                if (idToken != null) 'idToken': idToken,
              }),
            )
            .timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      debugPrint('[RankingService] Submit error: $e');
    }
  }

  static Future<bool> checkUsernameExists(String username) async {
    if (!isAvailable) {
      debugPrint('[RankingService] Firebase client not available');
      return false;
    }

    try {
      final trimmed = username.trim();
      if (trimmed.isEmpty) return false;

      final docSnap = await FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .doc(trimmed.toLowerCase())
          .get();
      if (docSnap.exists) return true;

      final querySnap = await FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .where('username', isEqualTo: trimmed)
          .limit(1)
          .get();
      return querySnap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[RankingService] Check username error: $e');
      return false;
    }
  }

  static Future<List<RankingEntry>> getRankings() async {
    if (!isAvailable) {
      debugPrint('[RankingService] Firebase client not available');
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .orderBy('score', descending: true)
          .limit(_maxRetrieved)
          .get();

      return snapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[RankingService] Get rankings error: $e');
      return [];
    }
  }

  static Future<List<RankingEntry>> getRankingsPage({
    required int offset,
    int limit = 10,
  }) async {
    if (!isAvailable) {
      debugPrint('[RankingService] Firebase client not available');
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .orderBy('score', descending: true)
          .limit(offset + limit)
          .get();

      if (offset >= snapshot.docs.length) return [];
      final slice = snapshot.docs.skip(offset).take(limit);
      return slice.map((doc) => RankingEntry.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('[RankingService] Get rankings page error: $e');
      return [];
    }
  }

  static Future<List<RankingEntry>> getRecentGames({int limit = 2}) async {
    if (!isAvailable) {
      debugPrint('[RankingService] Firebase client not available');
      return [];
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[RankingService] Get recent games error: $e');
      return [];
    }
  }
}
