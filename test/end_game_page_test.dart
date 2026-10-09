import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';

Widget _buildApp({required bool isWin, int level = 80}) {
  return LocaleProvider(
    locale: const Locale('pt'),
    onLocaleChanged: (_) {},
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt'), Locale('en')],
      home: EndGamePage(
        isWin: isWin,
        level: level,
        totalWordsCompleted: 15,
        accuracy: 94.0,
        averageSpeed: 1.8,
        wordTimes: const {0: 1.2, 1: 2.4},
        words: [
          WordModel(text: 'Foco', difficulty: 'easy'),
          WordModel(text: 'Teclado', difficulty: 'medium'),
        ],
      ),
    ),
  );
}

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

  group('EndGamePage - Widgets', () {
    testWidgets('renders win state and dashboard metrics', (tester) async {
      await tester.pumpWidget(_buildApp(isWin: true, level: 100));
      await tester.pump();

      expect(find.text('Ganhaste o jogo!'), findsOneWidget);
      expect(find.text('★ NOVO RECORDE!'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('pontos'), findsOneWidget);
      expect(find.text('Precisão'), findsOneWidget);
      expect(find.text('Palavras'), findsOneWidget);
      expect(find.text('Recomeçar'), findsOneWidget);
    });

    testWidgets('renders lose state correctly', (tester) async {
      await tester.pumpWidget(_buildApp(isWin: false, level: 45));
      await tester.pump();

      expect(find.text('Perdeste!'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Recomeçar'), findsOneWidget);
    });
  });
}
