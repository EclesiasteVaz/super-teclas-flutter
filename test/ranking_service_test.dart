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
    test('isAvailable returns false when Supabase not initialized', () {
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
  });
}
