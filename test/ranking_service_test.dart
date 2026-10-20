import 'package:flutter_test/flutter_test.dart';

import 'package:super_teclas/src/services/ranking_service.dart';

void main() {
  group('RankingEntry', () {
    test('fromMap creates entry with all fields', () {
      final map = {
        'username': 'player1',
        'score': 85,
        'words_completed': 12,
        'accuracy': 92.5,
        'average_speed': 2.3,
        'created_at': '2024-01-15T10:30:00Z',
      };

      final entry = RankingEntry.fromMap(map);

      expect(entry.username, 'player1');
      expect(entry.score, 85);
      expect(entry.wordsCompleted, 12);
      expect(entry.accuracy, 92.5);
      expect(entry.averageSpeed, 2.3);
      expect(entry.createdAt, isNotNull);
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
    });

    test('checkUsernameExists returns false when not available', () async {
      final exists = await RankingService.checkUsernameExists('test');
      expect(exists, isFalse);
    });

    test('executes start, submit, pause, resume, and timeout via server handler', () async {
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
  });
}
