import 'package:flutter_test/flutter_test.dart';

import 'package:super_teclas/src/data/models/word_model.dart';

void main() {
  group('WordModel', () {
    test('trims text on construction', () {
      final word = WordModel(text: '  Computador  ');
      expect(word.text, 'Computador');
    });

    test('preserves text without spaces', () {
      final word = WordModel(text: 'Telefone');
      expect(word.text, 'Telefone');
    });

    test('can update text after construction', () {
      final word = WordModel(text: 'Democracia');
      word.text = 'Expansionismo';
      expect(word.text, 'Expansionismo');
    });

    test('has default empty definition', () {
      final word = WordModel(text: 'Teste');
      expect(word.definition, '');
    });

    test('stores definition when provided', () {
      final word = WordModel(text: 'Casa', definition: 'Onde as pessoas moram');
      expect(word.definition, 'Onde as pessoas moram');
    });

    test('stores difficulty when provided', () {
      final word = WordModel(text: 'Teste', difficulty: 'hard');
      expect(word.difficulty, 'hard');
    });

    test('has default medium difficulty', () {
      final word = WordModel(text: 'Teste');
      expect(word.difficulty, 'medium');
    });

    test('calculates expectedDurationMs and basePoints by difficulty', () {
      final easyWord = WordModel(text: 'Casa', difficulty: 'easy');
      final mediumWord = WordModel(text: 'Teclado', difficulty: 'medium');
      final hardWord = WordModel(text: 'Paralelepipedo', difficulty: 'hard');

      expect(easyWord.basePoints, 100);
      expect(mediumWord.basePoints, 150);
      expect(hardWord.basePoints, 200);
      expect(easyWord.expectedDurationMs, greaterThanOrEqualTo(1200));
      expect(hardWord.expectedDurationMs,
          greaterThan(easyWord.expectedDurationMs));
    });

    test('calculates speed bonus points when faster than expected', () {
      final fastPoints = WordModel.calculateWordPoints(
        difficulty: 'medium',
        expectedDurationMs: 3000,
        actualDurationMs: 1500,
      );
      final slowPoints = WordModel.calculateWordPoints(
        difficulty: 'medium',
        expectedDurationMs: 3000,
        actualDurationMs: 4000,
      );

      expect(fastPoints, greaterThan(150));
      expect(slowPoints, 150);
    });

    test('serializes toMap and deserializes fromMap accurately', () {
      final original = WordModel(
        text: 'Algoritmo',
        difficulty: 'hard',
        definition: 'Sequencia finita de instrucoes',
        language: 'pt',
      );
      final map = original.toMap();
      final restored = WordModel.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.text, 'Algoritmo');
      expect(restored.difficulty, 'hard');
      expect(restored.definition, 'Sequencia finita de instrucoes');
      expect(restored.language, 'pt');
      expect(restored.expectedDurationMs, original.expectedDurationMs);
    });
  });
}
