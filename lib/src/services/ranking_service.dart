import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:super_teclas/src/config/env.dart';
import 'package:super_teclas/src/data/models/game_session_model.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';
import 'package:super_teclas/src/services/storage_service.dart';

class RankingEntry {
  final String username;
  final int score;
  final int wordsCompleted;
  final double accuracy;
  final double averageSpeed;
  final DateTime createdAt;
  final String sessionId;

  RankingEntry({
    required this.username,
    required this.score,
    required this.wordsCompleted,
    required this.accuracy,
    required this.averageSpeed,
    required this.createdAt,
    this.sessionId = '',
  });

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt =
        map['created_at'] ?? map['createdAt'] ?? map['updatedAt'];
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
      sessionId:
          ((map['sessionId'] ?? map['userId']) as String?)?.trim() ?? '',
    );
  }
}

class RankingService {
  static const _rankingsCollection = 'rankings';
  static const _gamesCollection = 'games';
  static const _sessionsCollection = 'sessions';
  static const _maxRetrieved = 20;
  static const _maxPauses = 3;
  static const _networkGraceMs = 500;
  static final Random _random = Random();
  static final Map<String, Map<String, dynamic>> _activeFirestoreGames = {};
  static bool _anonymousAuthFailed = false;

  static Future<Map<String, dynamic>?> Function(Map<String, dynamic> payload)?
      customActionHandler;
  static Stream<Map<String, dynamic>> Function(String gameId)?
      customSnapshotStreamFactory;

  @visibleForTesting
  static void resetTestState() {
    _activeFirestoreGames.clear();
    _anonymousAuthFailed = false;
    customActionHandler = null;
    customSnapshotStreamFactory = null;
  }

  static bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool get isServerAuthoritativeAvailable {
    if (customActionHandler != null) return true;
    return isAvailable;
  }

  static String _fallbackUsernameForSession(String sessionId) {
    final cleaned = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleaned.length >= 4
        ? cleaned.substring(cleaned.length - 4)
        : cleaned.padRight(4, '0');
    return 'Jogador_$suffix';
  }

  static Future<String> ensureAuthenticatedUser() async {
    final sessionId = await StorageService.getOrCreateSessionId();
    if (!isAvailable || _anonymousAuthFailed) {
      await StorageService.saveUserId(sessionId);
      return sessionId;
    }

    try {
      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;
      if (user == null) {
        final credential = await auth.signInAnonymously();
        user = credential.user;
      }
      final uid = (user?.uid != null && user!.uid.trim().isNotEmpty)
          ? user.uid.trim()
          : sessionId;
      await StorageService.saveUserId(uid);
      await StorageService.saveSessionId(sessionId);
      return uid;
    } catch (e) {
      _anonymousAuthFailed = true;
      debugPrint('[RankingService] Auth fallback to local session: $e');
      await StorageService.saveUserId(sessionId);
      return sessionId;
    }
  }

  static Future<String?> getSessionUsername() async {
    final localName = await StorageService.getUsername();
    if (localName != null && localName.isNotEmpty) {
      return localName;
    }
    if (!isAvailable) return null;

    try {
      final sessionId = await StorageService.getOrCreateSessionId();
      final doc = await FirebaseFirestore.instance
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();
      if (doc.exists && doc.data() != null) {
        final remoteName = (doc.data()!['username'] as String?)?.trim();
        if (remoteName != null && remoteName.isNotEmpty) {
          await StorageService.saveUsername(remoteName);
          return remoteName;
        }
      }
    } catch (_) {}
    return null;
  }

  static bool belongsToSession(
    Map<String, dynamic> data, {
    required String docId,
    required String sessionId,
    String? userId,
  }) {
    final normalizedSession = sessionId.trim();
    final normalizedUser = (userId ?? sessionId).trim();
    final docSessionId = (data['sessionId'] as String?)?.trim() ?? '';
    final docUserId = (data['userId'] as String?)?.trim() ?? '';
    if (normalizedSession.isNotEmpty && docId == normalizedSession) {
      return true;
    }
    if (docSessionId.isNotEmpty && normalizedSession.isNotEmpty) {
      return docSessionId == normalizedSession;
    }
    if (docUserId.isNotEmpty &&
        docUserId != 'anonymous' &&
        (docUserId == normalizedSession || docUserId == normalizedUser)) {
      return true;
    }
    return false;
  }

  static Future<bool> checkUsernameExists(
    String username, {
    String? currentSessionId,
  }) async {
    if (!isAvailable) {
      debugPrint('[RankingService] Firebase client not available');
      return false;
    }

    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();

    final sessionId =
        currentSessionId ?? await StorageService.getOrCreateSessionId();
    final userId = (await StorageService.getUserId()) ?? sessionId;
    final db = FirebaseFirestore.instance;

    try {
      final sessionQuery = await db
          .collection(_sessionsCollection)
          .where('usernameLower', isEqualTo: lower)
          .limit(5)
          .get();
      for (final doc in sessionQuery.docs) {
        if (!belongsToSession(
          doc.data(),
          docId: doc.id,
          sessionId: sessionId,
          userId: userId,
        )) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RankingService] Check session username error: $e');
    }

    try {
      final docSnap =
          await db.collection(_rankingsCollection).doc(lower).get();
      if (docSnap.exists && docSnap.data() != null) {
        if (!belongsToSession(
          docSnap.data()!,
          docId: docSnap.id,
          sessionId: sessionId,
          userId: userId,
        )) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[RankingService] Check ranking doc username error: $e');
    }

    try {
      final lowerQuery = await db
          .collection(_rankingsCollection)
          .where('usernameLower', isEqualTo: lower)
          .limit(5)
          .get();
      for (final doc in lowerQuery.docs) {
        if (!belongsToSession(
          doc.data(),
          docId: doc.id,
          sessionId: sessionId,
          userId: userId,
        )) {
          return true;
        }
      }
    } catch (_) {}

    try {
      final exactQuery = await db
          .collection(_rankingsCollection)
          .where('username', isEqualTo: trimmed)
          .limit(5)
          .get();
      for (final doc in exactQuery.docs) {
        if (!belongsToSession(
          doc.data(),
          docId: doc.id,
          sessionId: sessionId,
          userId: userId,
        )) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  static Future<bool> registerUsernameForSession(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return false;

    final sessionId = await StorageService.getOrCreateSessionId();
    final userId = await ensureAuthenticatedUser();
    var previousUsername = await StorageService.getUsername();

    if (isAvailable) {
      final taken = await checkUsernameExists(
        trimmed,
        currentSessionId: sessionId,
      );
      if (taken) return false;
    }

    if (isAvailable && (previousUsername == null || previousUsername.isEmpty)) {
      try {
        final sessionSnap = await FirebaseFirestore.instance
            .collection(_sessionsCollection)
            .doc(sessionId)
            .get();
        previousUsername = (sessionSnap.data()?['username'] as String?)?.trim();
      } catch (_) {}
    }

    await StorageService.saveUsername(trimmed);

    for (final entry in _activeFirestoreGames.values) {
      if (entry['sessionId'] == sessionId) {
        entry['username'] = trimmed;
      }
    }

    if (!isAvailable) return true;

    final db = FirebaseFirestore.instance;
    final lower = trimmed.toLowerCase();

    try {
      await db.collection(_sessionsCollection).doc(sessionId).set(
        {
          'sessionId': sessionId,
          'userId': userId,
          'username': trimmed,
          'usernameLower': lower,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[RankingService] Update session doc error: $e');
    }

    try {
      final docsById = <String, DocumentSnapshot<Map<String, dynamic>>>{};

      try {
        final bySession = await db
            .collection(_rankingsCollection)
            .where('sessionId', isEqualTo: sessionId)
            .get();
        for (final doc in bySession.docs) {
          docsById[doc.id] = doc;
        }
      } catch (_) {}

      if (userId != 'anonymous') {
        try {
          final byUser = await db
              .collection(_rankingsCollection)
              .where('userId', isEqualTo: userId)
              .get();
          for (final doc in byUser.docs) {
            docsById[doc.id] = doc;
          }
        } catch (_) {}
      }

      if (previousUsername != null &&
          previousUsername.trim().isNotEmpty &&
          previousUsername.trim().toLowerCase() != lower) {
        final prevId = previousUsername.trim().toLowerCase();
        if (!docsById.containsKey(prevId)) {
          try {
            final prevDoc =
                await db.collection(_rankingsCollection).doc(prevId).get();
            if (prevDoc.exists &&
                prevDoc.data() != null &&
                belongsToSession(
                  prevDoc.data()!,
                  docId: prevDoc.id,
                  sessionId: sessionId,
                  userId: userId,
                )) {
              docsById[prevDoc.id] = prevDoc;
            }
          } catch (_) {}
        }
      }

      for (final oldDoc in docsById.values) {
        final data = oldDoc.data();
        if (data == null) continue;
        if (!belongsToSession(
          data,
          docId: oldDoc.id,
          sessionId: sessionId,
          userId: userId,
        )) {
          continue;
        }

        if (oldDoc.id == lower) {
          await oldDoc.reference.set(
            {
              'username': trimmed,
              'usernameLower': lower,
              'sessionId': sessionId,
              'userId': userId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          final targetRef = db.collection(_rankingsCollection).doc(lower);
          final targetSnap = await targetRef.get();
          final targetData = targetSnap.data();
          final canWriteTarget = !targetSnap.exists ||
              targetData == null ||
              belongsToSession(
                targetData,
                docId: targetSnap.id,
                sessionId: sessionId,
                userId: userId,
              );
          if (canWriteTarget) {
            final oldScore = (data['score'] as num?)?.toInt() ?? 0;
            final targetScore = (targetData?['score'] as num?)?.toInt() ?? 0;
            if (!targetSnap.exists || oldScore >= targetScore) {
              await targetRef.set(
                {
                  ...data,
                  'sessionId': sessionId,
                  'userId': userId,
                  'username': trimmed,
                  'usernameLower': lower,
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            }
            await oldDoc.reference.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('[RankingService] Migrate ranking username error: $e');
    }

    return true;
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

  static int _getAllowedWordTimeMs(String text) {
    final clampedSeconds = text.trim().length.clamp(8, 15);
    return clampedSeconds * 1000;
  }

  static String _resolveSafeRankingDocId(
    String usernameLower,
    String sessionId,
  ) {
    final cleaned = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final suffix = cleaned.length >= 4
        ? cleaned.substring(cleaned.length - 4).toLowerCase()
        : cleaned.padRight(4, '0').toLowerCase();
    return '${usernameLower}_$suffix';
  }

  static Future<void> _promoteScoreToRankingInFirestore({
    required FirebaseFirestore db,
    required String sessionId,
    required String userId,
    required String username,
    required int score,
    required int wordsCompleted,
    required double accuracy,
    required double averageSpeed,
    required String gameId,
  }) async {
    await StorageService.saveHighScore(score);

    var resolvedUsername = username.trim();
    if (resolvedUsername.isEmpty) {
      resolvedUsername = (await getSessionUsername()) ?? '';
    }
    if (resolvedUsername.isEmpty) {
      resolvedUsername = _fallbackUsernameForSession(sessionId);
      await StorageService.saveUsername(resolvedUsername);
    }

    final lower = resolvedUsername.toLowerCase();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    try {
      final sessionRef = db.collection(_sessionsCollection).doc(sessionId);
      final sessionSnap = await sessionRef.get();
      final existingBest =
          (sessionSnap.data()?['bestScore'] as num?)?.toInt() ?? 0;
      final bestScore = score > existingBest ? score : existingBest;

      await sessionRef.set(
        {
          'sessionId': sessionId,
          'userId': userId,
          'username': resolvedUsername,
          'usernameLower': lower,
          'lastScore': score,
          'bestScore': bestScore,
          'lastGameId': gameId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    if (score <= 0) return;

    try {
      var targetDocId = lower;
      var rankingRef = db.collection(_rankingsCollection).doc(targetDocId);
      var existingSnap = await rankingRef.get();
      var existingData = existingSnap.data();

      if (existingSnap.exists &&
          existingData != null &&
          !belongsToSession(
            existingData,
            docId: existingSnap.id,
            sessionId: sessionId,
            userId: userId,
          )) {
        targetDocId = _resolveSafeRankingDocId(lower, sessionId);
        rankingRef = db.collection(_rankingsCollection).doc(targetDocId);
        existingSnap = await rankingRef.get();
        existingData = existingSnap.data();
      }

      final existingScore = (existingData?['score'] as num?)?.toInt() ?? 0;

      if (!existingSnap.exists || score >= existingScore) {
        await rankingRef.set(
          {
            'sessionId': sessionId,
            'userId': userId,
            'username': resolvedUsername,
            'usernameLower': lower,
            'score': score,
            'words_completed': wordsCompleted,
            'accuracy': accuracy,
            'average_speed': averageSpeed,
            'gameId': gameId,
            'created_at': nowIso,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        await rankingRef.set(
          {
            'sessionId': sessionId,
            'userId': userId,
            'username': resolvedUsername,
            'usernameLower': lower,
            'created_at': nowIso,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('[RankingService] Promote score to ranking error: $e');
    }
  }

  @visibleForTesting
  static Future<Map<String, dynamic>?> handleAuthoritativeGameAction(
    Map<String, dynamic> payload,
  ) async {
    return _handleFirestoreGameAction(payload, allowOfflineEngine: true);
  }

  static Future<Map<String, dynamic>?> _handleFirestoreGameAction(
    Map<String, dynamic> payload, {
    bool allowOfflineEngine = false,
  }) async {
    final firestoreReady = isAvailable;
    if (!firestoreReady && !allowOfflineEngine) return null;

    final db = firestoreReady ? FirebaseFirestore.instance : null;
    final action = (payload['action'] as String?)?.trim().toLowerCase() ?? '';
    final sessionId = await StorageService.getOrCreateSessionId();
    final userId = action == 'start'
        ? await ensureAuthenticatedUser()
        : ((await StorageService.getUserId()) ?? sessionId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (action == 'start') {
      final languageCode = payload['languageCode'] == 'en' ? 'en' : 'pt';
      var username = (payload['username'] as String?)?.trim() ?? '';
      if (username.isEmpty) {
        username = (await getSessionUsername()) ?? '';
      }

      await WordBank.load(languageCode: languageCode);
      final wordsPool = WordBank.getWords(languageCode);
      if (wordsPool.isEmpty) return null;

      final preferredWordId =
          (payload['initialWordId'] as String?)?.trim() ?? '';
      WordModel? matchedWord;
      if (preferredWordId.isNotEmpty) {
        for (final candidate in wordsPool) {
          if (candidate.id == preferredWordId) {
            matchedWord = candidate;
            break;
          }
        }
      }

      final firstWord =
          matchedWord ?? wordsPool[_random.nextInt(wordsPool.length)];
      final allowedTimeMs = _getAllowedWordTimeMs(firstWord.text);
      final wordDeadlineAtMs = nowMs + allowedTimeMs;
      final wordStartedAtIso =
          DateTime.fromMillisecondsSinceEpoch(nowMs).toUtc().toIso8601String();
      final wordDeadlineAtIso =
          DateTime.fromMillisecondsSinceEpoch(wordDeadlineAtMs)
              .toUtc()
              .toIso8601String();

      final gameRef = db?.collection(_gamesCollection).doc();
      final generatedGameId = gameRef?.id ??
          'game_${nowMs}_${_random.nextInt(999999).toString().padLeft(6, '0')}';

      final memoryGameDoc = <String, dynamic>{
        'gameId': generatedGameId,
        'sessionId': sessionId,
        'userId': userId,
        'username': username,
        'languageCode': languageCode,
        'status': 'running',
        'isWin': false,
        'score': 0,
        'validatedScore': 0,
        'lastWordPoints': 0,
        'wordsCompleted': 0,
        'totalWordsPool': wordsPool.length,
        'accuracy': 100.0,
        'averageSpeed': 0.0,
        'pauseCount': 0,
        'totalPausedDurationMs': 0,
        'currentWordPausedMs': 0,
        'pauseStartedAtMs': null,
        'currentWord': firstWord.toMap(),
        'usedWordIds': <String>[firstWord.id],
        'wordSequence': 1,
        'wordStartedAt': wordStartedAtIso,
        'wordStartedAtMs': nowMs,
        'wordDeadlineAt': wordDeadlineAtIso,
        'wordDeadlineAtMs': wordDeadlineAtMs,
        'remainingWordTimeMs': allowedTimeMs,
        'wordsLog': <Map<String, dynamic>>[],
        'validated': false,
        'startedAtMs': nowMs,
      };

      _activeFirestoreGames[generatedGameId] = memoryGameDoc;

      if (db != null && gameRef != null) {
        try {
          await gameRef.set({
            ...memoryGameDoc,
            'startedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('[RankingService] Create game doc error: $e');
        }

        try {
          await db.collection(_sessionsCollection).doc(sessionId).set(
            {
              'sessionId': sessionId,
              'userId': userId,
              if (username.isNotEmpty) 'username': username,
              if (username.isNotEmpty) 'usernameLower': username.toLowerCase(),
              'lastGameId': generatedGameId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[RankingService] Update session on start error: $e');
        }
      }

      return {
        'gameId': generatedGameId,
        'status': 'running',
        'isWin': false,
        'expired': false,
        'currentWord': firstWord.toMap(),
        'wordSequence': 1,
        'totalWordsPool': wordsPool.length,
        'allowedTimeMs': allowedTimeMs,
        'remainingTimeMs': allowedTimeMs,
        'serverNowMs': nowMs,
        'wordStartedAt': wordStartedAtIso,
        'wordStartedAtMs': nowMs,
        'wordDeadlineAt': wordDeadlineAtIso,
        'wordDeadlineAtMs': wordDeadlineAtMs,
        'score': 0,
        'lastWordPoints': 0,
        'wordsCompleted': 0,
        'pauseCount': 0,
        'remainingPauses': _maxPauses,
        'averageSpeed': 0.0,
      };
    }

    final gameId = (payload['gameId'] as String?)?.trim() ?? '';
    if (gameId.isEmpty) return null;

    final gameRef = db?.collection(_gamesCollection).doc(gameId);
    var game = _activeFirestoreGames[gameId];
    if (game == null && gameRef != null) {
      try {
        final gameSnap = await gameRef.get();
        if (gameSnap.exists && gameSnap.data() != null) {
          game = Map<String, dynamic>.from(gameSnap.data()!);
          _activeFirestoreGames[gameId] = game;
        }
      } catch (e) {
        debugPrint('[RankingService] Fetch game doc error: $e');
      }
    }
    if (game == null) return null;

    final currentStatus = (game['status'] as String?) ?? 'running';
    final currentScore = (game['score'] as num?)?.toInt() ?? 0;
    final currentWordsCompleted =
        (game['wordsCompleted'] as num?)?.toInt() ?? 0;
    final currentPauseCount = (game['pauseCount'] as num?)?.toInt() ?? 0;
    final currentAverageSpeed =
        (game['averageSpeed'] as num?)?.toDouble() ?? 0.0;
    final currentAccuracy = (payload['accuracy'] as num?)?.toDouble() ??
        (game['accuracy'] as num?)?.toDouble() ??
        100.0;
    final gameUsername = (game['username'] as String?)?.trim() ?? '';

    if (currentStatus == 'finished' || currentStatus == 'rejected') {
      return {
        'gameId': gameId,
        'status': currentStatus,
        'isWin': (game['isWin'] as bool?) ?? false,
        'expired': game['terminationReason'] == 'timeout',
        'score': currentScore,
        'lastWordPoints': (game['lastWordPoints'] as num?)?.toInt() ?? 0,
        'wordsCompleted': currentWordsCompleted,
        'pauseCount': currentPauseCount,
        'remainingPauses':
            (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
        'averageSpeed': currentAverageSpeed,
      };
    }

    final deadlineMs = (game['wordDeadlineAtMs'] as num?)?.toInt() ?? 0;

    if (action == 'timeout' ||
        (currentStatus == 'running' &&
            deadlineMs > 0 &&
            nowMs > deadlineMs + _networkGraceMs)) {
      game['status'] = 'finished';
      game['isWin'] = false;
      game['terminationReason'] = 'timeout';
      game['accuracy'] = currentAccuracy;
      game['validated'] = true;
      game['validatedScore'] = currentScore;
      game['wordDeadlineAt'] = null;
      game['wordDeadlineAtMs'] = null;
      game['finishedAtMs'] = nowMs;

      await StorageService.saveHighScore(currentScore);

      if (gameRef != null) {
        try {
          await gameRef.set(
            {
              'status': 'finished',
              'isWin': false,
              'terminationReason': 'timeout',
              'accuracy': currentAccuracy,
              'validated': true,
              'validatedScore': currentScore,
              'wordDeadlineAt': null,
              'wordDeadlineAtMs': null,
              'finishedAtMs': nowMs,
              'finishedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[RankingService] Update game timeout error: $e');
        }
      }

      if (db != null) {
        await _promoteScoreToRankingInFirestore(
          db: db,
          sessionId: (game['sessionId'] as String?) ?? sessionId,
          userId: (game['userId'] as String?) ?? userId,
          username: gameUsername,
          score: currentScore,
          wordsCompleted: currentWordsCompleted,
          accuracy: currentAccuracy,
          averageSpeed: currentAverageSpeed,
          gameId: gameId,
        );
      }

      return {
        'gameId': gameId,
        'status': 'finished',
        'isWin': false,
        'expired': true,
        'score': currentScore,
        'lastWordPoints': (game['lastWordPoints'] as num?)?.toInt() ?? 0,
        'wordsCompleted': currentWordsCompleted,
        'pauseCount': currentPauseCount,
        'remainingPauses':
            (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
        'averageSpeed': currentAverageSpeed,
      };
    }

    if (action == 'pause') {
      if (currentStatus != 'running' || currentPauseCount >= _maxPauses) {
        return {
          'gameId': gameId,
          'status': currentStatus,
          'pauseCount': currentPauseCount,
          'remainingPauses':
              (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
          'score': currentScore,
          'wordsCompleted': currentWordsCompleted,
          if (currentPauseCount >= _maxPauses)
            'error': 'Maximum allowed pauses (3) exceeded',
        };
      }

      final effectiveDeadline = deadlineMs > 0 ? deadlineMs : nowMs + 8000;
      final remainingWordTimeMs =
          (effectiveDeadline - nowMs).clamp(1000, 15000);
      final newPauseCount = currentPauseCount + 1;

      game['status'] = 'paused';
      game['pauseCount'] = newPauseCount;
      game['pauseStartedAtMs'] = nowMs;
      game['remainingWordTimeMs'] = remainingWordTimeMs;
      game['wordDeadlineAt'] = null;
      game['wordDeadlineAtMs'] = null;

      if (gameRef != null) {
        try {
          await gameRef.set(
            {
              'status': 'paused',
              'pauseCount': newPauseCount,
              'pauseStartedAtMs': nowMs,
              'remainingWordTimeMs': remainingWordTimeMs,
              'wordDeadlineAt': null,
              'wordDeadlineAtMs': null,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[RankingService] Update game pause error: $e');
        }
      }

      return {
        'gameId': gameId,
        'status': 'paused',
        'isWin': false,
        'expired': false,
        'pauseCount': newPauseCount,
        'remainingPauses': _maxPauses - newPauseCount,
        'remainingTimeMs': remainingWordTimeMs,
        'serverNowMs': nowMs,
        'score': currentScore,
        'wordsCompleted': currentWordsCompleted,
      };
    }

    if (action == 'resume') {
      if (currentStatus != 'paused') {
        return {
          'gameId': gameId,
          'status': currentStatus,
          'pauseCount': currentPauseCount,
          'remainingPauses':
              (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
          'score': currentScore,
          'wordsCompleted': currentWordsCompleted,
        };
      }

      final pauseStartedAtMs =
          (game['pauseStartedAtMs'] as num?)?.toInt() ?? nowMs;
      final pausedDurationMs = (nowMs - pauseStartedAtMs).clamp(0, 3600000);
      final newTotalPausedDurationMs =
          ((game['totalPausedDurationMs'] as num?)?.toInt() ?? 0) +
              pausedDurationMs;
      final newCurrentWordPausedMs =
          ((game['currentWordPausedMs'] as num?)?.toInt() ?? 0) +
              pausedDurationMs;
      final remainingWordTimeMs =
          ((game['remainingWordTimeMs'] as num?)?.toInt() ?? 8000)
               .clamp(1000, 15000);
      final newDeadlineAtMs = nowMs + remainingWordTimeMs;
      final newDeadlineAtIso =
          DateTime.fromMillisecondsSinceEpoch(newDeadlineAtMs)
              .toUtc()
              .toIso8601String();
      final currentSequence = (game['wordSequence'] as num?)?.toInt() ?? 1;

      game['status'] = 'running';
      game['pauseStartedAtMs'] = null;
      game['totalPausedDurationMs'] = newTotalPausedDurationMs;
      game['currentWordPausedMs'] = newCurrentWordPausedMs;
      game['wordDeadlineAt'] = newDeadlineAtIso;
      game['wordDeadlineAtMs'] = newDeadlineAtMs;

      if (gameRef != null) {
        try {
          await gameRef.set(
            {
              'status': 'running',
              'pauseStartedAtMs': null,
              'totalPausedDurationMs': newTotalPausedDurationMs,
              'currentWordPausedMs': newCurrentWordPausedMs,
              'wordDeadlineAt': newDeadlineAtIso,
              'wordDeadlineAtMs': newDeadlineAtMs,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[RankingService] Update game resume error: $e');
        }
      }

      return {
        'gameId': gameId,
        'status': 'running',
        'isWin': false,
        'expired': false,
        'currentWord': game['currentWord'],
        'wordSequence': currentSequence,
        'pauseCount': currentPauseCount,
        'remainingPauses':
            (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
        'remainingTimeMs': remainingWordTimeMs,
        'serverNowMs': nowMs,
        'wordDeadlineAt': newDeadlineAtIso,
        'wordDeadlineAtMs': newDeadlineAtMs,
        'score': currentScore,
        'wordsCompleted': currentWordsCompleted,
      };
    }

    if (action == 'submit') {
      if (currentStatus != 'running') return null;

      final typedWord = (payload['word'] as String?)?.trim() ?? '';
      final rawCurrentWord = game['currentWord'];
      if (rawCurrentWord is! Map) return null;

      final languageCode = (game['languageCode'] as String?) ?? 'pt';
      final activeWord = WordModel.fromMap(
        Map<String, dynamic>.from(rawCurrentWord),
        defaultLanguage: languageCode,
      );

      if (typedWord != activeWord.text) {
        return {
          'gameId': gameId,
          'valid': false,
          'status': currentStatus,
          'error': 'Submitted word does not match current word',
        };
      }

      final wordStartedAtMs =
          (game['wordStartedAtMs'] as num?)?.toInt() ?? nowMs;
      final currentWordPausedMs =
          (game['currentWordPausedMs'] as num?)?.toInt() ?? 0;
      final actualDurationMs =
          (nowMs - wordStartedAtMs - currentWordPausedMs).clamp(1, 600000);

      final wordPoints = WordModel.calculateWordPoints(
        difficulty: activeWord.difficulty,
        expectedDurationMs: activeWord.expectedDurationMs,
        actualDurationMs: actualDurationMs,
      );

      final newScore = currentScore + wordPoints;
      final logEntry = <String, dynamic>{
        'wordId': activeWord.id,
        'wordText': activeWord.text,
        'difficulty': activeWord.difficulty,
        'length': activeWord.length,
        'expectedDurationMs': activeWord.expectedDurationMs,
        'actualDurationMs': actualDurationMs,
        'startedAt': DateTime.fromMillisecondsSinceEpoch(wordStartedAtMs)
            .toUtc()
            .toIso8601String(),
        'completedAt': DateTime.fromMillisecondsSinceEpoch(nowMs)
            .toUtc()
            .toIso8601String(),
        'stateWhenTyped': 'running',
        'pointsAwarded': wordPoints,
      };

      final existingLogs = (game['wordsLog'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];
      final wordsLog = [...existingLogs, logEntry];
      final newWordsCompleted = wordsLog.length;

      var sumDurationMs = 0;
      for (final entry in wordsLog) {
        sumDurationMs += (entry['actualDurationMs'] as num?)?.toInt() ?? 0;
      }
      final averageSpeed = double.parse(
        (sumDurationMs / newWordsCompleted / 1000.0).toStringAsFixed(2),
      );

      final wordsPool = WordBank.getWords(languageCode);
      final usedWordIds = (game['usedWordIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[activeWord.id];
      if (!usedWordIds.contains(activeWord.id)) {
        usedWordIds.add(activeWord.id);
      }

      final unusedWords =
          wordsPool.where((w) => !usedWordIds.contains(w.id)).toList();

      if (unusedWords.isEmpty) {
        game['status'] = 'finished';
        game['isWin'] = true;
        game['terminationReason'] = 'completed_all_words';
        game['score'] = newScore;
        game['validatedScore'] = newScore;
        game['lastWordPoints'] = wordPoints;
        game['wordsCompleted'] = newWordsCompleted;
        game['averageSpeed'] = averageSpeed;
        game['accuracy'] = currentAccuracy;
        game['wordsLog'] = wordsLog;
        game['usedWordIds'] = usedWordIds;
        game['wordDeadlineAt'] = null;
        game['wordDeadlineAtMs'] = null;
        game['validated'] = true;
        game['finishedAtMs'] = nowMs;

        await StorageService.saveHighScore(newScore);

        if (gameRef != null) {
          try {
            await gameRef.set(
              {
                'status': 'finished',
                'isWin': true,
                'terminationReason': 'completed_all_words',
                'score': newScore,
                'validatedScore': newScore,
                'lastWordPoints': wordPoints,
                'wordsCompleted': newWordsCompleted,
                'averageSpeed': averageSpeed,
                'accuracy': currentAccuracy,
                'wordsLog': wordsLog,
                'usedWordIds': usedWordIds,
                'wordDeadlineAt': null,
                'wordDeadlineAtMs': null,
                'validated': true,
                'finishedAtMs': nowMs,
                'finishedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          } catch (e) {
            debugPrint('[RankingService] Update game win error: $e');
          }
        }

        if (db != null) {
          await _promoteScoreToRankingInFirestore(
            db: db,
            sessionId: (game['sessionId'] as String?) ?? sessionId,
            userId: (game['userId'] as String?) ?? userId,
            username: gameUsername,
            score: newScore,
            wordsCompleted: newWordsCompleted,
            accuracy: currentAccuracy,
            averageSpeed: averageSpeed,
            gameId: gameId,
          );
        }

        return {
          'gameId': gameId,
          'status': 'finished',
          'isWin': true,
          'expired': false,
          'score': newScore,
          'lastWordPoints': wordPoints,
          'wordsCompleted': newWordsCompleted,
          'pauseCount': currentPauseCount,
          'remainingPauses':
              (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
          'averageSpeed': averageSpeed,
          'actualDurationMs': actualDurationMs,
        };
      }

      final nextWord = unusedWords[_random.nextInt(unusedWords.length)];
      usedWordIds.add(nextWord.id);
      final nextSequence = ((game['wordSequence'] as num?)?.toInt() ?? 1) + 1;
      final allowedTimeMs = _getAllowedWordTimeMs(nextWord.text);
      final nextDeadlineAtMs = nowMs + allowedTimeMs;
      final wordStartedAtIso =
          DateTime.fromMillisecondsSinceEpoch(nowMs).toUtc().toIso8601String();
      final nextDeadlineAtIso =
          DateTime.fromMillisecondsSinceEpoch(nextDeadlineAtMs)
              .toUtc()
              .toIso8601String();

      game['status'] = 'running';
      game['currentWord'] = nextWord.toMap();
      game['usedWordIds'] = usedWordIds;
      game['wordSequence'] = nextSequence;
      game['wordStartedAt'] = wordStartedAtIso;
      game['wordStartedAtMs'] = nowMs;
      game['wordDeadlineAt'] = nextDeadlineAtIso;
      game['wordDeadlineAtMs'] = nextDeadlineAtMs;
      game['remainingWordTimeMs'] = allowedTimeMs;
      game['currentWordPausedMs'] = 0;
      game['score'] = newScore;
      game['validatedScore'] = newScore;
      game['lastWordPoints'] = wordPoints;
      game['wordsCompleted'] = newWordsCompleted;
      game['totalWordsPool'] = wordsPool.length;
      game['averageSpeed'] = averageSpeed;
      game['accuracy'] = currentAccuracy;
      game['wordsLog'] = wordsLog;

      if (gameRef != null) {
        try {
          await gameRef.set(
            {
              'status': 'running',
              'currentWord': nextWord.toMap(),
              'usedWordIds': usedWordIds,
              'wordSequence': nextSequence,
              'wordStartedAt': wordStartedAtIso,
              'wordStartedAtMs': nowMs,
              'wordDeadlineAt': nextDeadlineAtIso,
              'wordDeadlineAtMs': nextDeadlineAtMs,
              'remainingWordTimeMs': allowedTimeMs,
              'currentWordPausedMs': 0,
              'score': newScore,
              'validatedScore': newScore,
              'lastWordPoints': wordPoints,
              'wordsCompleted': newWordsCompleted,
              'totalWordsPool': wordsPool.length,
              'averageSpeed': averageSpeed,
              'accuracy': currentAccuracy,
              'wordsLog': wordsLog,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[RankingService] Update game submit error: $e');
        }
      }

      return {
        'gameId': gameId,
        'status': 'running',
        'isWin': false,
        'expired': false,
        'currentWord': nextWord.toMap(),
        'wordSequence': nextSequence,
        'totalWordsPool': wordsPool.length,
        'allowedTimeMs': allowedTimeMs,
        'remainingTimeMs': allowedTimeMs,
        'serverNowMs': nowMs,
        'wordStartedAt': wordStartedAtIso,
        'wordStartedAtMs': nowMs,
        'wordDeadlineAt': nextDeadlineAtIso,
        'wordDeadlineAtMs': nextDeadlineAtMs,
        'score': newScore,
        'lastWordPoints': wordPoints,
        'wordsCompleted': newWordsCompleted,
        'pauseCount': currentPauseCount,
        'remainingPauses':
            (_maxPauses - currentPauseCount).clamp(0, _maxPauses),
        'averageSpeed': averageSpeed,
        'actualDurationMs': actualDurationMs,
      };
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _postGameAction(
    Map<String, dynamic> payload,
  ) async {
    if (customActionHandler != null) {
      return await customActionHandler!(payload);
    }

    if (!isAvailable) return null;

    final baseUrl = Env.apiBaseUrl.trim();
    if (baseUrl.isNotEmpty) {
      try {
        final sessionId = await StorageService.getOrCreateSessionId();
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
                'sessionId': sessionId,
                if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (e) {
        debugPrint('[RankingService] HTTP game action fallback to Firestore: $e');
      }
    }

    try {
      return await _handleFirestoreGameAction(payload);
    } catch (e) {
      debugPrint('[RankingService] Firestore game action error: $e');
      return null;
    }
  }

  static Future<ServerGameStepResult?> startServerGameSession({
    required String languageCode,
    String? username,
    String? initialWordId,
  }) async {
    if (!isServerAuthoritativeAvailable) return null;

    try {
      final resolvedUsername =
          username ?? (await StorageService.getUsername()) ?? '';
      final response = await _postGameAction({
        'action': 'start',
        'languageCode': languageCode == 'en' ? 'en' : 'pt',
        'username': resolvedUsername,
        if (initialWordId != null && initialWordId.trim().isNotEmpty)
          'initialWordId': initialWordId.trim(),
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
    if (response == null || response['valid'] == false) return null;
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
    await StorageService.saveHighScore(score);

    if (!isAvailable && customActionHandler == null) {
      debugPrint('[RankingService] Firebase client not available');
      return;
    }

    var effectiveScore = score;
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
      if (localValidation.recalculatedScore > 0) {
        effectiveScore = localValidation.recalculatedScore;
      }
    }

    try {
      final targetGameId = session?.gameId;

      if (customActionHandler != null) {
        if (targetGameId == null ||
            targetGameId.isEmpty ||
            targetGameId.startsWith('local_')) {
          return;
        }
        await customActionHandler!({
          'action': 'validate',
          'gameId': targetGameId,
          'username': username,
          'accuracy': accuracy,
        });
        return;
      }

      final sessionId = await StorageService.getOrCreateSessionId();

      if (Env.apiBaseUrl.trim().isNotEmpty &&
          targetGameId != null &&
          targetGameId.isNotEmpty &&
          !targetGameId.startsWith('local_')) {
        try {
          final idToken = await _getIdToken();
          final uri = Uri.parse(
            '${Env.apiBaseUrl.replaceAll(RegExp(r'/$'), '')}/api/validate-game',
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
                  'gameId': targetGameId,
                  'sessionId': sessionId,
                  'username': username,
                  'accuracy': accuracy,
                  if (idToken != null) 'idToken': idToken,
                }),
              )
              .timeout(const Duration(seconds: 8));
          if (response.statusCode == 422 || response.statusCode == 403) {
            return;
          }
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return;
          }
        } catch (_) {}
      }

      if (isAvailable) {
        final db = FirebaseFirestore.instance;
        final userId = await ensureAuthenticatedUser();
        final resolvedGameId =
            (targetGameId != null && targetGameId.isNotEmpty)
                ? targetGameId
                : 'game_${DateTime.now().millisecondsSinceEpoch}';

        final alreadyFinalizedInMemory =
            _activeFirestoreGames[resolvedGameId]?['validated'] == true;

        if (session != null && !alreadyFinalizedInMemory) {
          try {
            await db.collection(_gamesCollection).doc(resolvedGameId).set(
              {
                ...session.toMap(),
                'gameId': resolvedGameId,
                'sessionId': sessionId,
                'userId': userId,
                'username': username,
                'score': effectiveScore,
                'validatedScore': effectiveScore,
                'validated': true,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          } catch (e) {
            debugPrint('[RankingService] Save game session error: $e');
          }
        }

        await _promoteScoreToRankingInFirestore(
          db: db,
          sessionId: sessionId,
          userId: userId,
          username: username,
          score: effectiveScore,
          wordsCompleted: wordsCompleted,
          accuracy: accuracy,
          averageSpeed: averageSpeed,
          gameId: resolvedGameId,
        );
      }
    } catch (e) {
      debugPrint('[RankingService] Submit error: $e');
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
          .where((entry) => entry.username.trim().isNotEmpty && entry.score > 0)
          .toList();
    } catch (e) {
      debugPrint('[RankingService] Get rankings error: $e');
      return [];
    }
  }

  static Stream<List<RankingEntry>>? watchRankings({int limit = _maxRetrieved}) {
    if (!isAvailable) return null;
    try {
      return FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .orderBy('score', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => RankingEntry.fromMap(doc.data()))
                .where(
                  (entry) =>
                      entry.username.trim().isNotEmpty && entry.score > 0,
                )
                .toList(),
          );
    } catch (_) {
      return null;
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

      final validDocs = snapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .where((entry) => entry.username.trim().isNotEmpty && entry.score > 0)
          .toList();
      if (offset >= validDocs.length) return [];
      return validDocs.skip(offset).take(limit).toList();
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

      final entries = snapshot.docs
          .map((doc) => RankingEntry.fromMap(doc.data()))
          .where((entry) => entry.username.trim().isNotEmpty && entry.score > 0)
          .toList();
      if (entries.isNotEmpty) {
        return entries;
      }
    } catch (e) {
      debugPrint('[RankingService] Get recent games error: $e');
    }

    try {
      final fallback = await getRankings();
      fallback.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return fallback.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  static Stream<List<RankingEntry>>? watchRecentGames({int limit = 2}) {
    if (!isAvailable) return null;
    try {
      return FirebaseFirestore.instance
          .collection(_rankingsCollection)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => RankingEntry.fromMap(doc.data()))
                .where(
                  (entry) =>
                      entry.username.trim().isNotEmpty && entry.score > 0,
                )
                .toList(),
          );
    } catch (_) {
      return null;
    }
  }
}
