import 'package:flutter_test/flutter_test.dart';

import 'package:super_teclas/src/data/models/game_session_model.dart';
import 'package:super_teclas/src/services/game_service.dart';

void main() {
  group('GameService', () {
    late GameService gameService;

    setUp(() {
      gameService = GameService();
    });

    test('initializes with a random word in running state', () {
      expect(gameService.words.contains(gameService.currentWord), isTrue);
      expect(gameService.indexWordUseds, contains(gameService.currentIndex));
      expect(gameService.isWin, isFalse);
      expect(gameService.status, GameStatus.running);
      expect(gameService.isRunning, isTrue);
      expect(gameService.isPaused, isFalse);
      expect(gameService.isFinished, isFalse);
    });

    test('notifies listeners on construction', () {
      int notifyCount = 0;
      gameService.addListener(() => notifyCount++);
      final gs = GameService();
      gs.addListener(() => notifyCount++);
      expect(notifyCount, 0);
    });

    test('writing with incorrect length does nothing', () {
      final initialIndex = gameService.currentIndex;
      gameService.writing(word: 'a');
      expect(gameService.currentIndex, initialIndex);
      expect(gameService.isWin, isFalse);
    });

    test('writing with correct length but wrong text does nothing', () {
      final initialIndex = gameService.currentIndex;
      final currentText = gameService.currentWord.text;
      final wrongWord = 'x' * currentText.length;
      gameService.writing(word: wrongWord);
      expect(gameService.currentIndex, initialIndex);
      expect(gameService.isWin, isFalse);
    });

    test('writing correct word advances to next word and increases score', () {
      final correctWord = gameService.currentWord.text;
      final initialIndex = gameService.currentIndex;
      gameService.writing(word: correctWord);
      expect(gameService.currentIndex, isNot(initialIndex));
      expect(gameService.indexWordUseds.length, 2);
      expect(gameService.isWin, isFalse);
      expect(gameService.score, greaterThan(0));
      expect(gameService.wordsLog.length, 1);
      expect(gameService.wordsLog.first.wordText, correctWord);
      expect(gameService.wordsLog.first.stateWhenTyped, 'running');
    });

    test('writing correct word notifies listeners', () {
      int notifyCount = 0;
      gameService.addListener(() => notifyCount++);
      final correctWord = gameService.currentWord.text;
      gameService.writing(word: correctWord);
      expect(notifyCount, 1);
    });

    test('completing all words sets isWin to true and status to finished', () {
      const maxAttempts = 100;
      int attempts = 0;
      while (!gameService.isWin && attempts < maxAttempts) {
        final word = gameService.currentWord.text;
        gameService.writing(word: word);
        attempts++;
      }
      expect(gameService.isWin, isTrue);
      expect(gameService.status, GameStatus.finished);
      expect(gameService.isFinished, isTrue);
      expect(attempts, gameService.words.length - 1);
    });

    test('every word is unique during a full playthrough', () {
      final totalWords = gameService.words.length;
      final usedIndices = <int>{gameService.currentIndex};

      const maxAttempts = 100;
      int attempts = 0;
      while (!gameService.isWin && attempts < maxAttempts) {
        final word = gameService.currentWord.text;
        gameService.writing(word: word);
        attempts++;
        if (!gameService.isWin) {
          expect(
            usedIndices.contains(gameService.currentIndex),
            isFalse,
            reason: 'Index ${gameService.currentIndex} was already used',
          );
          usedIndices.add(gameService.currentIndex);
        }
      }

      expect(gameService.isWin, isTrue);
      expect(usedIndices.length, totalWords - 1);
    });

    test('writing after win does not change state', () {
      const maxAttempts = 100;
      int attempts = 0;
      while (!gameService.isWin && attempts < maxAttempts) {
        final word = gameService.currentWord.text;
        gameService.writing(word: word);
        attempts++;
      }

      expect(gameService.isWin, isTrue);
      final lastIndex = gameService.currentIndex;
      final finalScore = gameService.score;

      gameService.writing(word: 'anything');
      expect(gameService.currentIndex, lastIndex);
      expect(gameService.score, finalScore);
      expect(gameService.isWin, isTrue);
    });

    test('blocks word registration and score increase while paused', () {
      final initialIndex = gameService.currentIndex;
      final currentWordText = gameService.currentWord.text;

      expect(gameService.pauseGame(), isTrue);
      expect(gameService.isPaused, isTrue);

      gameService.recordKeystroke();
      gameService.addCorrectKeystroke();
      gameService.writing(word: currentWordText);

      expect(gameService.currentIndex, initialIndex);
      expect(gameService.totalWordsCompleted, 0);
      expect(gameService.score, 0);
      expect(gameService.totalKeystrokes, 0);
      expect(gameService.correctKeystrokes, 0);
      expect(gameService.wordsLog, isEmpty);

      expect(gameService.resumeGame(), isTrue);
      expect(gameService.isRunning, isTrue);

      gameService.writing(word: currentWordText);
      expect(gameService.totalWordsCompleted, 1);
      expect(gameService.score, greaterThan(0));
    });

    test('blocks word registration and score increase when finished', () {
      final currentWordText = gameService.currentWord.text;
      gameService.finishGame(win: false);
      expect(gameService.isFinished, isTrue);

      gameService.recordKeystroke();
      gameService.addCorrectKeystroke();
      gameService.writing(word: currentWordText);

      expect(gameService.totalWordsCompleted, 0);
      expect(gameService.score, 0);
      expect(gameService.wordsLog, isEmpty);
    });

    test('enforces maximum of 3 pauses per match', () {
      expect(gameService.pauseGame(), isTrue);
      expect(gameService.resumeGame(), isTrue);

      expect(gameService.pauseGame(), isTrue);
      expect(gameService.resumeGame(), isTrue);

      expect(gameService.pauseGame(), isTrue);
      expect(gameService.resumeGame(), isTrue);

      expect(gameService.pauseCount, 3);
      expect(gameService.remainingPauses, 0);
      expect(gameService.canPause, isFalse);
      expect(gameService.pauseGame(), isFalse);
      expect(gameService.isRunning, isTrue);
    });

    test('wordTimes records time for each completed word', () {
      final index = gameService.currentIndex;
      final correctWord = gameService.currentWord.text;
      gameService.writing(word: correctWord);

      expect(gameService.wordTimes.length, 1);
      expect(gameService.wordTimes.containsKey(index), isTrue);
    });

    test('averageTimePerWord returns 0 when no words completed', () {
      expect(gameService.averageTimePerWord, 0);
    });

    test('averageTimePerWord returns average after completing words', () {
      for (var i = 0; i < 3; i++) {
        final word = gameService.currentWord.text;
        gameService.writing(word: word);
      }

      expect(gameService.wordTimes.length, 3);
      expect(gameService.averageTimePerWord, isNonNegative);
    });

    test('fastestWordText returns empty when no words completed', () {
      expect(gameService.fastestWordText, '');
    });

    test('slowestWordText returns empty when no words completed', () {
      expect(gameService.slowestWordText, '');
    });

    test('fastestWordText returns a word after completing words', () {
      gameService.writing(word: gameService.currentWord.text);
      gameService.writing(word: gameService.currentWord.text);

      expect(gameService.fastestWordText.isNotEmpty, isTrue);
      expect(gameService.slowestWordText.isNotEmpty, isTrue);
    });

    test('wordTimes does not include current word before completion', () {
      final initialLength = gameService.wordTimes.length;
      gameService.recordKeystroke();
      expect(gameService.wordTimes.length, initialLength);
    });
  });

  group('GameSessionModel Anti-Cheat Validation', () {
    test('accepts valid finished session and recalculates score', () {
      final start = DateTime.now().subtract(const Duration(seconds: 10));
      final finish = DateTime.now();
      final session = GameSessionModel(
        gameId: 'game_1',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 150,
        wordsCompleted: 1,
        accuracy: 100,
        averageSpeed: 2.0,
        pauseCount: 1,
        totalPausedDurationMs: 1000,
        startedAt: start,
        finishedAt: finish,
        wordsLog: [
          GameWordLog(
            wordId: 'pt_computador',
            wordText: 'Computador',
            difficulty: 'medium',
            length: 10,
            expectedDurationMs: 4000,
            actualDurationMs: 2000,
            startedAt: start,
            completedAt: start.add(const Duration(seconds: 2)),
            stateWhenTyped: 'running',
            pointsAwarded: 188,
          ),
        ],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isTrue);
      expect(result.recalculatedScore, 188);
    });

    test('rejects session if status is not finished', () {
      final now = DateTime.now();
      final session = GameSessionModel(
        gameId: 'game_2',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.running,
        score: 0,
        wordsCompleted: 0,
        accuracy: 100,
        averageSpeed: 0,
        pauseCount: 0,
        totalPausedDurationMs: 0,
        startedAt: now,
        wordsLog: const [],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });

    test('rejects session if word was typed below biomechanical limit', () {
      final start = DateTime.now().subtract(const Duration(seconds: 5));
      final finish = DateTime.now();
      final session = GameSessionModel(
        gameId: 'game_3',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 200,
        wordsCompleted: 1,
        accuracy: 100,
        averageSpeed: 0.05,
        pauseCount: 0,
        totalPausedDurationMs: 0,
        startedAt: start,
        finishedAt: finish,
        wordsLog: [
          GameWordLog(
            wordId: 'pt_computador',
            wordText: 'Computador',
            difficulty: 'medium',
            length: 10,
            expectedDurationMs: 4000,
            actualDurationMs: 50,
            startedAt: start,
            completedAt: start.add(const Duration(milliseconds: 50)),
            stateWhenTyped: 'running',
            pointsAwarded: 225,
          ),
        ],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });

    test('rejects session if word was registered in paused state', () {
      final start = DateTime.now().subtract(const Duration(seconds: 5));
      final finish = DateTime.now();
      final session = GameSessionModel(
        gameId: 'game_4',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 150,
        wordsCompleted: 1,
        accuracy: 100,
        averageSpeed: 2.0,
        pauseCount: 1,
        totalPausedDurationMs: 1000,
        startedAt: start,
        finishedAt: finish,
        wordsLog: [
          GameWordLog(
            wordId: 'pt_computador',
            wordText: 'Computador',
            difficulty: 'medium',
            length: 10,
            expectedDurationMs: 4000,
            actualDurationMs: 2000,
            startedAt: start,
            completedAt: start.add(const Duration(seconds: 2)),
            stateWhenTyped: 'paused',
            pointsAwarded: 188,
          ),
        ],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });

    test('rejects session if pauseCount exceeds 3', () {
      final now = DateTime.now();
      final session = GameSessionModel(
        gameId: 'game_5',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 0,
        wordsCompleted: 0,
        accuracy: 100,
        averageSpeed: 0,
        pauseCount: 4,
        totalPausedDurationMs: 2000,
        startedAt: now.subtract(const Duration(seconds: 5)),
        finishedAt: now,
        wordsLog: const [],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });

    test('rejects session if duplicate words are present in wordsLog', () {
      final start = DateTime.now().subtract(const Duration(seconds: 10));
      final finish = DateTime.now();
      final entry = GameWordLog(
        wordId: 'pt_computador',
        wordText: 'Computador',
        difficulty: 'medium',
        length: 10,
        expectedDurationMs: 4000,
        actualDurationMs: 2000,
        startedAt: start,
        completedAt: start.add(const Duration(seconds: 2)),
        stateWhenTyped: 'running',
        pointsAwarded: 188,
      );
      final session = GameSessionModel(
        gameId: 'game_6',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 376,
        wordsCompleted: 2,
        accuracy: 100,
        averageSpeed: 2.0,
        pauseCount: 0,
        totalPausedDurationMs: 0,
        startedAt: start,
        finishedAt: finish,
        wordsLog: [entry, entry],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });

    test('rejects session if total session duration is shorter than word and pause times', () {
      final start = DateTime.now();
      final finish = start.add(const Duration(seconds: 1));
      final session = GameSessionModel(
        gameId: 'game_7',
        userId: 'user_1',
        username: 'player1',
        languageCode: 'pt',
        status: GameStatus.finished,
        score: 150,
        wordsCompleted: 1,
        accuracy: 100,
        averageSpeed: 4.0,
        pauseCount: 1,
        totalPausedDurationMs: 3000,
        startedAt: start,
        finishedAt: finish,
        wordsLog: [
          GameWordLog(
            wordId: 'pt_computador',
            wordText: 'Computador',
            difficulty: 'medium',
            length: 10,
            expectedDurationMs: 4000,
            actualDurationMs: 4000,
            startedAt: start,
            completedAt: start.add(const Duration(seconds: 4)),
            stateWhenTyped: 'running',
            pointsAwarded: 150,
          ),
        ],
      );

      final result = GameSessionModel.validateSession(session);
      expect(result.isValid, isFalse);
    });
  });

  group('GameService Server-Authoritative Mode', () {
    test('applyServerStart sets single word and server pool metadata', () {
      final gs = GameService();
      final step = ServerGameStepResult.fromMap({
        'gameId': 'srv_game_1',
        'status': 'running',
        'isWin': false,
        'currentWord': {
          'id': 'pt_computador',
          'text': 'Computador',
          'difficulty': 'medium',
          'language': 'pt',
          'expectedDurationMs': 4000,
        },
        'wordSequence': 1,
        'totalWordsPool': 250,
        'allowedTimeMs': 10000,
        'remainingTimeMs': 10000,
        'wordDeadlineAtMs':
            DateTime.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch,
        'score': 0,
        'wordsCompleted': 0,
        'pauseCount': 0,
      });

      gs.applyServerStart(step);

      expect(gs.isServerAuthoritative, isTrue);
      expect(gs.gameId, 'srv_game_1');
      expect(gs.words.length, 1);
      expect(gs.currentWord.text, 'Computador');
      expect(gs.sessionTotalWords, 250);
      expect(gs.getTimeForWord(), 10);
      expect(gs.getRemainingSecondsFromDeadline(), inInclusiveRange(9, 10));
    });

    test('applyServerStep advances to next server word and logs completed word', () {
      final gs = GameService();
      gs.applyServerStart(
        ServerGameStepResult.fromMap({
          'gameId': 'srv_game_2',
          'status': 'running',
          'currentWord': {
            'id': 'pt_foco',
            'text': 'Foco',
            'difficulty': 'easy',
            'language': 'pt',
            'expectedDurationMs': 1400,
          },
          'totalWordsPool': 200,
          'allowedTimeMs': 8000,
          'remainingTimeMs': 8000,
        }),
      );

      gs.applyServerStep(
        ServerGameStepResult.fromMap({
          'gameId': 'srv_game_2',
          'status': 'running',
          'currentWord': {
            'id': 'pt_teclado',
            'text': 'Teclado',
            'difficulty': 'medium',
            'language': 'pt',
            'expectedDurationMs': 2800,
          },
          'wordSequence': 2,
          'totalWordsPool': 200,
          'allowedTimeMs': 8000,
          'remainingTimeMs': 8000,
          'score': 135,
          'lastWordPoints': 135,
          'wordsCompleted': 1,
          'actualDurationMs': 900,
        }),
      );

      expect(gs.words.length, 2);
      expect(gs.currentWord.text, 'Teclado');
      expect(gs.currentIndex, 1);
      expect(gs.score, 135);
      expect(gs.lastWordPoints, 135);
      expect(gs.totalWordsCompleted, 1);
      expect(gs.wordsLog.length, 1);
      expect(gs.wordsLog.first.wordText, 'Foco');
      expect(gs.wordTimes[0], closeTo(0.9, 0.01));
    });

    test('applyServerStep transitions to finished when backend times out', () {
      final gs = GameService();
      gs.applyServerStart(
        ServerGameStepResult.fromMap({
          'gameId': 'srv_game_3',
          'status': 'running',
          'currentWord': {
            'id': 'pt_foco',
            'text': 'Foco',
            'difficulty': 'easy',
            'language': 'pt',
          },
        }),
      );

      gs.applyServerStep(
        ServerGameStepResult.fromMap({
          'gameId': 'srv_game_3',
          'status': 'finished',
          'isWin': false,
          'expired': true,
          'score': 120,
          'wordsCompleted': 1,
        }),
      );

      expect(gs.isFinished, isTrue);
      expect(gs.isWin, isFalse);
      expect(gs.score, 120);
      expect(gs.wordDeadlineAt, isNull);
    });

    test('applyServerStart resets pre-start keystrokes and handles server clock skew', () {
      final gs = GameService();
      gs.recordKeystroke();
      gs.recordKeystroke();
      expect(gs.totalKeystrokes, 2);

      const skewedServerNowMs = 1000000;
      const skewedDeadlineMs = 1012000;

      gs.applyServerStart(
        ServerGameStepResult.fromMap({
          'gameId': 'srv_game_skew',
          'status': 'running',
          'currentWord': {
            'id': 'pt_computador',
            'text': 'Computador',
            'difficulty': 'medium',
            'language': 'pt',
          },
          'wordSequence': 1,
          'totalWordsPool': 200,
          'allowedTimeMs': 12000,
          'remainingTimeMs': 12000,
          'serverNowMs': skewedServerNowMs,
          'wordDeadlineAtMs': skewedDeadlineMs,
        }),
      );

      expect(gs.totalKeystrokes, 0);
      expect(gs.correctKeystrokes, 0);
      expect(gs.accuracy, 100);
      expect(gs.getRemainingSecondsFromDeadline(), inInclusiveRange(11, 12));
    });
  });
}
