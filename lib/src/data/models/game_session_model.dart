import 'package:super_teclas/src/data/models/word_model.dart';

enum GameStatus {
  running,
  paused,
  finished,
}

class GameWordLog {
  final String wordId;
  final String wordText;
  final String difficulty;
  final int length;
  final int expectedDurationMs;
  final int actualDurationMs;
  final DateTime startedAt;
  final DateTime completedAt;
  final String stateWhenTyped;
  final int pointsAwarded;

  const GameWordLog({
    required this.wordId,
    required this.wordText,
    required this.difficulty,
    required this.length,
    required this.expectedDurationMs,
    required this.actualDurationMs,
    required this.startedAt,
    required this.completedAt,
    required this.stateWhenTyped,
    required this.pointsAwarded,
  });

  factory GameWordLog.fromMap(Map<String, dynamic> map) {
    final text = (map['wordText'] as String?) ?? '';
    final diff = (map['difficulty'] as String?) ?? 'medium';
    final expected = (map['expectedDurationMs'] as num?)?.toInt() ??
        WordModel.calculateExpectedDurationMs(text, diff);
    final actual = (map['actualDurationMs'] as num?)?.toInt() ?? 0;

    return GameWordLog(
      wordId: (map['wordId'] as String?) ?? '',
      wordText: text,
      difficulty: diff,
      length: (map['length'] as num?)?.toInt() ?? text.length,
      expectedDurationMs: expected,
      actualDurationMs: actual,
      startedAt: DateTime.tryParse((map['startedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: DateTime.tryParse((map['completedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      stateWhenTyped: (map['stateWhenTyped'] as String?) ?? 'running',
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ??
          WordModel.calculateWordPoints(
            difficulty: diff,
            expectedDurationMs: expected,
            actualDurationMs: actual,
          ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wordId': wordId,
      'wordText': wordText,
      'difficulty': difficulty,
      'length': length,
      'expectedDurationMs': expectedDurationMs,
      'actualDurationMs': actualDurationMs,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'completedAt': completedAt.toUtc().toIso8601String(),
      'stateWhenTyped': stateWhenTyped,
      'pointsAwarded': pointsAwarded,
    };
  }
}

class GameValidationResult {
  final bool isValid;
  final int recalculatedScore;
  final String? rejectionReason;

  const GameValidationResult({
    required this.isValid,
    required this.recalculatedScore,
    this.rejectionReason,
  });
}

class ServerGameStepResult {
  final String gameId;
  final GameStatus status;
  final bool isWin;
  final bool expired;
  final bool rejected;
  final WordModel? currentWord;
  final int wordSequence;
  final int totalWordsPool;
  final int allowedTimeMs;
  final int remainingTimeMs;
  final int? serverNowMs;
  final int? wordDeadlineAtMs;
  final int score;
  final int lastWordPoints;
  final int wordsCompleted;
  final int pauseCount;
  final int remainingPauses;
  final double averageSpeed;
  final int actualDurationMs;
  final String? error;

  const ServerGameStepResult({
    required this.gameId,
    required this.status,
    this.isWin = false,
    this.expired = false,
    this.rejected = false,
    this.currentWord,
    this.wordSequence = 1,
    this.totalWordsPool = 200,
    this.allowedTimeMs = 8000,
    this.remainingTimeMs = 8000,
    this.serverNowMs,
    this.wordDeadlineAtMs,
    this.score = 0,
    this.lastWordPoints = 0,
    this.wordsCompleted = 0,
    this.pauseCount = 0,
    this.remainingPauses = 3,
    this.averageSpeed = 0,
    this.actualDurationMs = 0,
    this.error,
  });

  factory ServerGameStepResult.fromMap(
    Map<String, dynamic> map, {
    String defaultLanguage = 'pt',
  }) {
    final rawStatus = (map['status'] as String?)?.toLowerCase() ?? 'running';
    final parsedStatus = switch (rawStatus) {
      'paused' => GameStatus.paused,
      'finished' || 'rejected' => GameStatus.finished,
      _ => GameStatus.running,
    };

    WordModel? parsedWord;
    final rawWord = map['currentWord'];
    if (rawWord is Map) {
      parsedWord = WordModel.fromMap(
        Map<String, dynamic>.from(rawWord),
        defaultLanguage: defaultLanguage,
      );
    }

    final allowedMs = (map['allowedTimeMs'] as num?)?.toInt() ??
        (parsedWord != null
            ? parsedWord.text.length.clamp(8, 15) * 1000
            : 8000);
    final remainingMs =
        ((map['remainingTimeMs'] ?? map['remainingWordTimeMs']) as num?)
                ?.toInt() ??
            allowedMs;
    final pauseCount = (map['pauseCount'] as num?)?.toInt() ?? 0;

    int? parsedDeadlineMs = (map['wordDeadlineAtMs'] as num?)?.toInt();
    if (parsedDeadlineMs == null) {
      final rawDeadline = map['wordDeadlineAt'];
      if (rawDeadline is num) {
        parsedDeadlineMs = rawDeadline.toInt();
      } else if (rawDeadline is String) {
        parsedDeadlineMs =
            DateTime.tryParse(rawDeadline)?.millisecondsSinceEpoch;
      }
    }

    return ServerGameStepResult(
      gameId: (map['gameId'] as String?) ?? '',
      status: parsedStatus,
      isWin: (map['isWin'] as bool?) ?? false,
      expired: (map['expired'] as bool?) ??
          ((map['terminationReason'] as String?) == 'timeout'),
      rejected: rawStatus == 'rejected',
      currentWord: parsedWord,
      wordSequence: (map['wordSequence'] as num?)?.toInt() ?? 1,
      totalWordsPool: (map['totalWordsPool'] as num?)?.toInt() ?? 200,
      allowedTimeMs: allowedMs,
      remainingTimeMs: remainingMs,
      serverNowMs: (map['serverNowMs'] as num?)?.toInt(),
      wordDeadlineAtMs: parsedDeadlineMs,
      score: (map['score'] as num?)?.toInt() ?? 0,
      lastWordPoints: (map['lastWordPoints'] as num?)?.toInt() ?? 0,
      wordsCompleted: (map['wordsCompleted'] as num?)?.toInt() ?? 0,
      pauseCount: pauseCount,
      remainingPauses: (map['remainingPauses'] as num?)?.toInt() ??
          (3 - pauseCount).clamp(0, 3),
      averageSpeed: (map['averageSpeed'] as num?)?.toDouble() ?? 0.0,
      actualDurationMs: (map['actualDurationMs'] as num?)?.toInt() ?? 0,
      error: (map['error'] ?? map['reason']) as String?,
    );
  }
}

class GameSessionModel {
  final String gameId;
  final String userId;
  final String username;
  final String languageCode;
  final GameStatus status;
  final int score;
  final int wordsCompleted;
  final double accuracy;
  final double averageSpeed;
  final int pauseCount;
  final int totalPausedDurationMs;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<GameWordLog> wordsLog;
  final bool validated;

  const GameSessionModel({
    required this.gameId,
    required this.userId,
    required this.username,
    required this.languageCode,
    required this.status,
    required this.score,
    required this.wordsCompleted,
    required this.accuracy,
    required this.averageSpeed,
    required this.pauseCount,
    required this.totalPausedDurationMs,
    required this.startedAt,
    this.finishedAt,
    required this.wordsLog,
    this.validated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'userId': userId,
      'username': username,
      'languageCode': languageCode,
      'status': status.name,
      'score': score,
      'wordsCompleted': wordsCompleted,
      'accuracy': accuracy,
      'averageSpeed': averageSpeed,
      'pauseCount': pauseCount,
      'totalPausedDurationMs': totalPausedDurationMs,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'finishedAt': finishedAt?.toUtc().toIso8601String(),
      'wordsLog': wordsLog.map((e) => e.toMap()).toList(),
      'validated': validated,
    };
  }

  static GameValidationResult validateSession(
    GameSessionModel session, {
    bool enforceBiomechanicalLimit = true,
  }) {
    if (session.status != GameStatus.finished) {
      return const GameValidationResult(
        isValid: false,
        recalculatedScore: 0,
        rejectionReason: 'Game status must be finished before validation',
      );
    }

    if (session.pauseCount > 3) {
      return const GameValidationResult(
        isValid: false,
        recalculatedScore: 0,
        rejectionReason: 'Maximum allowed pauses (3) exceeded',
      );
    }

    if (session.wordsCompleted != session.wordsLog.length) {
      return const GameValidationResult(
        isValid: false,
        recalculatedScore: 0,
        rejectionReason: 'wordsCompleted does not match wordsLog length',
      );
    }

    if (session.accuracy < 0 || session.accuracy > 100) {
      return const GameValidationResult(
        isValid: false,
        recalculatedScore: 0,
        rejectionReason: 'Invalid accuracy value',
      );
    }

    final seenWords = <String>{};
    var recalculatedScore = 0;
    var sumActualDurationMs = 0;

    for (final entry in session.wordsLog) {
      final trimmed = entry.wordText.trim();
      if (trimmed.isEmpty) {
        return const GameValidationResult(
          isValid: false,
          recalculatedScore: 0,
          rejectionReason: 'Empty wordText in wordsLog',
        );
      }

      final key = trimmed.toLowerCase();
      if (seenWords.contains(key)) {
        return GameValidationResult(
          isValid: false,
          recalculatedScore: 0,
          rejectionReason: 'Duplicate word detected in session: $trimmed',
        );
      }
      seenWords.add(key);

      if (entry.stateWhenTyped != GameStatus.running.name) {
        return const GameValidationResult(
          isValid: false,
          recalculatedScore: 0,
          rejectionReason:
              'Word registered while game was not in running state',
        );
      }

      final minHumanDurationMs = trimmed.length * 40;
      if (enforceBiomechanicalLimit &&
          entry.actualDurationMs < minHumanDurationMs) {
        return GameValidationResult(
          isValid: false,
          recalculatedScore: 0,
          rejectionReason:
              'Biomechanical speed limit violated for word "$trimmed"',
        );
      }

      final expected = entry.expectedDurationMs > 0
          ? entry.expectedDurationMs
          : WordModel.calculateExpectedDurationMs(trimmed, entry.difficulty);

      recalculatedScore += WordModel.calculateWordPoints(
        difficulty: entry.difficulty,
        expectedDurationMs: expected,
        actualDurationMs: entry.actualDurationMs,
      );
      sumActualDurationMs += entry.actualDurationMs;
    }

    if (session.finishedAt != null) {
      final sessionDurationMs =
          session.finishedAt!.difference(session.startedAt).inMilliseconds;
      if (sessionDurationMs + 1500 <
          sumActualDurationMs + session.totalPausedDurationMs) {
        return const GameValidationResult(
          isValid: false,
          recalculatedScore: 0,
          rejectionReason:
              'Session duration is shorter than sum of word and pause times',
        );
      }
    }

    return GameValidationResult(
      isValid: true,
      recalculatedScore: recalculatedScore,
    );
  }
}
