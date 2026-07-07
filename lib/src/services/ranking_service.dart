import 'package:supabase_flutter/supabase_flutter.dart';

class RankingEntry {
  final String username;
  final int score;
  final int wordsCompleted;
  final double accuracy;
  final DateTime createdAt;

  RankingEntry({
    required this.username,
    required this.score,
    required this.wordsCompleted,
    required this.accuracy,
    required this.createdAt,
  });

  factory RankingEntry.fromMap(Map<String, dynamic> map) {
    return RankingEntry(
      username: map['username'] as String,
      score: map['score'] as int,
      wordsCompleted: map['words_completed'] as int? ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class RankingService {
  static const _tableName = 'rankings';
  static const _maxRetrieved = 20;

  static bool get isAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> submitScore({
    required String username,
    required int score,
    required int wordsCompleted,
    required double accuracy,
  }) async {
    if (!isAvailable) return;

    try {
      await Supabase.instance.client.from(_tableName).insert({
        'username': username,
        'score': score,
        'words_completed': wordsCompleted,
        'accuracy': accuracy,
      });
    } catch (_) {}
  }

  static Future<List<RankingEntry>> getRankings() async {
    if (!isAvailable) return [];

    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .order('score', ascending: false)
          .limit(_maxRetrieved);

      return (response as List<dynamic>)
          .map((e) => RankingEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
