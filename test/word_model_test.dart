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
  });
}
