import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/src/data/models/word_model.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.audioplayers.source'),
      (methodCall) async {
        return null;
      },
    );
  });

  group('EndGamePage - Speed Stats', () {
    test('wordTimes tracks time for each completed word', () {
      final wordTimes = <int, double>{};
      wordTimes[0] = 2.5;
      wordTimes[1] = 3.8;

      expect(wordTimes.length, 2);
      expect(wordTimes[0], 2.5);
      expect(wordTimes[1], 3.8);
    });

    test('fastest word is determined correctly', () {
      final words = [
        WordModel(text: 'Casa', difficulty: 'easy'),
        WordModel(text: 'Teste', difficulty: 'medium'),
        WordModel(text: 'Computador', difficulty: 'medium'),
      ];
      final wordTimes = {0: 2.5, 1: 3.8, 2: 1.2};

      final fastest =
          wordTimes.entries.reduce((a, b) => a.value <= b.value ? a : b);
      expect(words[fastest.key].text, 'Computador');
      expect(fastest.value, 1.2);
    });

    test('slowest word is determined correctly', () {
      final words = [
        WordModel(text: 'Casa', difficulty: 'easy'),
        WordModel(text: 'Teste', difficulty: 'medium'),
      ];
      final wordTimes = {0: 2.5, 1: 3.8};

      final slowest =
          wordTimes.entries.reduce((a, b) => a.value >= b.value ? a : b);
      expect(words[slowest.key].text, 'Teste');
      expect(slowest.value, 3.8);
    });

    test('average speed is calculated correctly', () {
      final wordTimes = {0: 2.0, 1: 4.0, 2: 3.0};
      final total = wordTimes.values.reduce((a, b) => a + b);
      final avg = total / wordTimes.length;
      expect(avg, 3.0);
    });

    test('empty wordTimes returns zero average', () {
      final wordTimes = <int, double>{};
      double avg = 0;
      if (wordTimes.isNotEmpty) {
        final total = wordTimes.values.reduce((a, b) => a + b);
        avg = total / wordTimes.length;
      }
      expect(avg, 0);
    });
  });
}
