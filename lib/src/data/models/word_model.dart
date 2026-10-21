class WordModel {
  final String id;
  String text;
  final String difficulty;
  final String definition;
  final String language;
  final int expectedDurationMs;

  WordModel({
    required this.text,
    this.difficulty = 'medium',
    this.definition = '',
    this.language = 'pt',
    String? id,
    int? expectedDurationMs,
  })  : id = id ?? _buildId(language, text),
        expectedDurationMs = expectedDurationMs ??
            calculateExpectedDurationMs(text, difficulty) {
    text = text.trim();
  }

  int get length => text.length;

  int get basePoints => calculateBasePoints(difficulty);

  static String _buildId(String language, String rawText) {
    final normalized = rawText
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u00C0-\u017F_-]'), '_');
    return '${language}_$normalized';
  }

  static int calculateExpectedDurationMs(String text, String difficulty) {
    final trimmed = text.trim();
    final factor = switch (difficulty.toLowerCase()) {
      'easy' => 350,
      'hard' => 450,
      _ => 400,
    };
    return (trimmed.length * factor).clamp(1200, 15000);
  }

  static int calculateBasePoints(String difficulty) {
    return switch (difficulty.toLowerCase()) {
      'easy' => 100,
      'hard' => 200,
      _ => 150,
    };
  }

  static int calculateWordPoints({
    required String difficulty,
    required int expectedDurationMs,
    required int actualDurationMs,
  }) {
    final basePoints = calculateBasePoints(difficulty);
    if (actualDurationMs <= 0 ||
        expectedDurationMs <= 0 ||
        actualDurationMs >= expectedDurationMs) {
      return basePoints;
    }
    final maxBonus = basePoints ~/ 2;
    final ratio = (expectedDurationMs - actualDurationMs) / expectedDurationMs;
    final bonus = (ratio * maxBonus).round().clamp(0, maxBonus);
    return basePoints + bonus;
  }

  factory WordModel.fromMap(
    Map<String, dynamic> map, {
    String defaultLanguage = 'pt',
    String? docId,
  }) {
    final wordText = (map['text'] ?? map['word'] ?? '') as String;
    final diff = (map['difficulty'] as String?) ?? 'medium';
    final lang = (map['language'] as String?) ?? defaultLanguage;
    final expected = (map['expectedDurationMs'] as num?)?.toInt();

    return WordModel(
      id: docId ?? (map['id'] as String?),
      text: wordText,
      difficulty: diff,
      definition: (map['definition'] as String?) ?? '',
      language: lang,
      expectedDurationMs: expected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': text,
      'text': text,
      'difficulty': difficulty,
      'definition': definition,
      'language': language,
      'length': length,
      'expectedDurationMs': expectedDurationMs,
    };
  }
}
