import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RankingEntry', () {
    test('fromMap creates entry with all fields', () {
      final map = {
        'username': 'player1',
        'score': 85,
        'words_completed': 12,
        'accuracy': 92.5,
        'average_speed': 2.3,
        'created_at': '2024-01-15T10:30:00Z',
        'sessionId': 'sess_123',
      };

      final entry = RankingEntry.fromMap(map);

      expect(entry.username, 'player1');
      expect(entry.score, 85);
      expect(entry.wordsCompleted, 12);
      expect(entry.accuracy, 92.5);
      expect(entry.averageSpeed, 2.3);
      expect(entry.createdAt, isNotNull);
      expect(entry.sessionId, 'sess_123');
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'username': 'player2',
        'score': 50,
        'words_completed': null,
        'accuracy': null,
        'average_speed': null,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final entry = RankingEntry.fromMap(map);

      expect(entry.username, 'player2');
      expect(entry.score, 50);
      expect(entry.wordsCompleted, 0);
      expect(entry.accuracy, 0.0);
      expect(entry.averageSpeed, 0.0);
    });
  });

  group('StorageService & Session Identity', () {
    test('generates and persists a unique local sessionId', () async {
      final firstId = await StorageService.getOrCreateSessionId();
      final secondId = await StorageService.getOrCreateSessionId();

      expect(firstId, isNotEmpty);
      expect(firstId, isNot('anonymous'));
      expect(firstId, startsWith('sess_'));
      expect(secondId, equals(firstId));
      expect(await StorageService.getSessionId(), equals(firstId));
      expect(await StorageService.getUserId(), equals(firstId));
    });

    test('registers username and binds it to local session', () async {
      final sessionId = await StorageService.getOrCreateSessionId();
      final ok =
          await RankingService.registerUsernameForSession('  SuperDev  ');

      expect(ok, isTrue);
      expect(await StorageService.getUsername(), 'SuperDev');
      expect(await RankingService.getSessionUsername(), 'SuperDev');
      expect(await RankingService.ensureAuthenticatedUser(), equals(sessionId));
    });

    test('persists only the highest score locally', () async {
      expect(await StorageService.getHighScore(), 0);
      await StorageService.saveHighScore(120);
      expect(await StorageService.getHighScore(), 120);
      await StorageService.saveHighScore(80);
      expect(await StorageService.getHighScore(), 120);
      await StorageService.saveHighScore(250);
      expect(await StorageService.getHighScore(), 250);
    });
  });

  group('RankingService', () {
    test('isAvailable returns false when Firebase not initialized', () {
      expect(RankingService.isAvailable, isFalse);
    });

    test('getRankings returns empty list when not available', () async {
      final rankings = await RankingService.getRankings();
      expect(rankings, isEmpty);
    });

    test('getRankingsPage returns empty list when not available', () async {
      final rankings = await RankingService.getRankingsPage(offset: 0);
      expect(rankings, isEmpty);
    });

    test('getRecentGames returns empty list when not available', () async {
      final recent = await RankingService.getRecentGames();
      expect(recent, isEmpty);
    });

    test('submitScore does nothing when not available', () async {
      await RankingService.submitScore(
        username: 'test',
        score: 100,
        wordsCompleted: 10,
        accuracy: 95.0,
        averageSpeed: 1.5,
      );
      expect(await StorageService.getHighScore(), 100);
    });

    test('checkUsernameExists returns false when not available', () async {
      final exists = await RankingService.checkUsernameExists('test');
      expect(exists, isFalse);
    });

    test(
        'executes start, submit, pause, resume, and timeout via server handler',
        () async {
      final capturedActions = <String>[];
      RankingService.customActionHandler = (payload) async {
        final action = payload['action'] as String;
        capturedActions.add(action);
        if (action == 'start') {
          return {
            'gameId': 'remote_123',
            'status': 'running',
            'currentWord': {
              'id': 'pt_computador',
              'text': 'Computador',
              'difficulty': 'medium',
              'language': 'pt',
            },
            'wordSequence': 1,
            'totalWordsPool': 180,
            'allowedTimeMs': 10000,
            'remainingTimeMs': 10000,
            'score': 0,
            'wordsCompleted': 0,
            'pauseCount': 0,
          };
        }
        if (action == 'submit') {
          return {
            'gameId': 'remote_123',
            'status': 'running',
            'currentWord': {
              'id': 'pt_telefone',
              'text': 'Telefone',
              'difficulty': 'easy',
              'language': 'pt',
            },
            'wordSequence': 2,
            'totalWordsPool': 180,
            'allowedTimeMs': 8000,
            'remainingTimeMs': 8000,
            'score': 175,
            'lastWordPoints': 175,
            'wordsCompleted': 1,
            'pauseCount': 0,
            'actualDurationMs': 1500,
          };
        }
        if (action == 'pause') {
          return {
            'gameId': 'remote_123',
            'status': 'paused',
            'pauseCount': 1,
            'remainingPauses': 2,
            'remainingTimeMs': 5400,
            'score': 175,
            'wordsCompleted': 1,
          };
        }
        if (action == 'resume') {
          return {
            'gameId': 'remote_123',
            'status': 'running',
            'pauseCount': 1,
            'remainingPauses': 2,
            'remainingTimeMs': 5400,
            'score': 175,
            'wordsCompleted': 1,
          };
        }
        return {
          'gameId': 'remote_123',
          'status': 'finished',
          'isWin': false,
          'expired': true,
          'score': 175,
          'wordsCompleted': 1,
        };
      };

      try {
        final started = await RankingService.startServerGameSession(
          languageCode: 'pt',
          username: 'tester',
        );
        expect(started, isNotNull);
        expect(started!.gameId, 'remote_123');
        expect(started.currentWord?.text, 'Computador');

        final submitted = await RankingService.submitWordToServer(
          gameId: 'remote_123',
          word: 'Computador',
          accuracy: 100,
        );
        expect(submitted, isNotNull);
        expect(submitted!.currentWord?.text, 'Telefone');
        expect(submitted.score, 175);

        final paused = await RankingService.pauseGameOnServer(
          gameId: 'remote_123',
        );
        expect(paused, isNotNull);
        expect(paused!.status.name, 'paused');
        expect(paused.remainingTimeMs, 5400);

        final resumed = await RankingService.resumeGameOnServer(
          gameId: 'remote_123',
        );
        expect(resumed, isNotNull);
        expect(resumed!.status.name, 'running');

        final timedOut = await RankingService.timeoutGameOnServer(
          gameId: 'remote_123',
        );
        expect(timedOut, isNotNull);
        expect(timedOut!.status.name, 'finished');
        expect(timedOut.expired, isTrue);

        expect(
          capturedActions,
          ['start', 'submit', 'pause', 'resume', 'timeout'],
        );
      } finally {
        RankingService.customActionHandler = null;
      }
    });

    test('belongsToSession verifies sessionId and userId ownership', () {
      expect(
        RankingService.belongsToSession(
          {'sessionId': 'sess_1', 'userId': 'uid_1'},
          docId: 'sess_1',
          sessionId: 'sess_1',
          userId: 'uid_2',
        ),
        isTrue,
      );
      expect(
        RankingService.belongsToSession(
          {'sessionId': 'sess_2', 'userId': 'uid_1'},
          docId: 'sess_2',
          sessionId: 'sess_1',
          userId: 'uid_1',
        ),
        isFalse,
      );
      expect(
        RankingService.belongsToSession(
          {'userId': 'uid_1'},
          docId: 'uid_1',
          sessionId: 'sess_1',
          userId: 'uid_1',
        ),
        isTrue,
      );
      expect(
        RankingService.belongsToSession(
          {'userId': 'uid_2'},
          docId: 'uid_2',
          sessionId: 'sess_1',
          userId: 'uid_1',
        ),
        isFalse,
      );
    });

    test(
        'handleAuthoritativeGameAction manages full lifecycle and enforces max 3 pauses',
        () async {
      RankingService.resetTestState();

      final started = await RankingService.handleAuthoritativeGameAction({
        'action': 'start',
        'languageCode': 'pt',
        'username': 'AuthoritativeUser',
        'initialWordId': 'pt_computador',
      });
      expect(started, isNotNull);
      final gameId = started!['gameId'] as String;
      expect(started['status'], 'running');
      expect((started['currentWord'] as Map)['text'], 'Computador');

      final invalidSubmit = await RankingService.handleAuthoritativeGameAction({
        'action': 'submit',
        'gameId': gameId,
        'word': 'Errada',
      });
      expect(invalidSubmit, isNotNull);
      expect(invalidSubmit!['valid'], isFalse);
      expect(invalidSubmit['status'], 'running');

      final validSubmit = await RankingService.handleAuthoritativeGameAction({
        'action': 'submit',
        'gameId': gameId,
        'word': 'Computador',
        'accuracy': 96.5,
      });
      expect(validSubmit, isNotNull);
      expect(validSubmit!['status'], 'running');
      expect(validSubmit['wordsCompleted'], 1);
      expect(validSubmit['score'] as int, greaterThan(0));
      expect(validSubmit['wordSequence'], 2);

      for (var i = 1; i <= 3; i++) {
        final paused = await RankingService.handleAuthoritativeGameAction({
          'action': 'pause',
          'gameId': gameId,
        });
        expect(paused!['status'], 'paused');
        expect(paused['pauseCount'], i);
        expect(paused['remainingPauses'], 3 - i);

        final resumed = await RankingService.handleAuthoritativeGameAction({
          'action': 'resume',
          'gameId': gameId,
        });
        expect(resumed!['status'], 'running');
      }

      final fourthPause = await RankingService.handleAuthoritativeGameAction({
        'action': 'pause',
        'gameId': gameId,
      });
      expect(fourthPause!['status'], 'running');
      expect(fourthPause['pauseCount'], 3);
      expect(fourthPause['remainingPauses'], 0);
      expect(fourthPause['error'], isNotNull);

      final timedOut = await RankingService.handleAuthoritativeGameAction({
        'action': 'timeout',
        'gameId': gameId,
        'wordSequence': 2,
        'reason': 'client_timer_expired',
      });
      expect(timedOut!['status'], 'finished');
      expect(timedOut['expired'], isTrue);
      expect(timedOut['isWin'], isFalse);
    });
  });
}
