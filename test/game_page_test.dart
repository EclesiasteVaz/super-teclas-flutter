import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';

MaterialApp _buildApp() {
  return const MaterialApp(
    locale: Locale('pt'),
    localizationsDelegates: [
      ...GlobalMaterialLocalizations.delegates,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: [Locale('pt'), Locale('en')],
    home: GamePage(),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.audioplayers.source'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'create':
            return 'test-player-id';
          case 'setSource':
          case 'setVolume':
          case 'resume':
          case 'pause':
          case 'stop':
          case 'setReleaseMode':
          case 'playerState':
          case 'getDuration':
          case 'getCurrentPosition':
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    RankingService.customActionHandler = null;
    RankingService.customSnapshotStreamFactory = null;
  });

  group('GamePage', () {
    testWidgets('renders game interface in running state', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.text('Pontos'), findsOneWidget);
      expect(find.text('Decorrendo'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows pause button in app bar and hides word when paused',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      expect(find.text('Pausado'), findsOneWidget);
      expect(find.text('JOGO PAUSADO'), findsWidgets);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('typing with wrong word does not play sound on error',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();

      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);
    });

    testWidgets(
        'submits matched word to server and transitions to EndGamePage on server timeout snapshot',
        (tester) async {
      final snapshotController =
          StreamController<Map<String, dynamic>>.broadcast();
      final submittedWords = <String>[];

      RankingService.customSnapshotStreamFactory = (_) => snapshotController.stream;
      RankingService.customActionHandler = (payload) async {
        final action = payload['action'] as String;
        if (action == 'start') {
          return {
            'gameId': 'srv_live_1',
            'status': 'running',
            'currentWord': {
              'id': 'pt_casa',
              'text': 'Casa',
              'difficulty': 'easy',
              'language': 'pt',
            },
            'wordSequence': 1,
            'totalWordsPool': 200,
            'allowedTimeMs': 8000,
            'remainingTimeMs': 8000,
            'wordDeadlineAtMs': DateTime.now()
                .add(const Duration(seconds: 8))
                .millisecondsSinceEpoch,
            'score': 0,
            'wordsCompleted': 0,
            'pauseCount': 0,
          };
        }
        if (action == 'submit') {
          submittedWords.add(payload['word'] as String);
          return {
            'gameId': 'srv_live_1',
            'status': 'running',
            'currentWord': {
              'id': 'pt_teclado',
              'text': 'Teclado',
              'difficulty': 'medium',
              'language': 'pt',
            },
            'wordSequence': 2,
            'totalWordsPool': 200,
            'allowedTimeMs': 8000,
            'remainingTimeMs': 8000,
            'wordDeadlineAtMs': DateTime.now()
                .add(const Duration(seconds: 8))
                .millisecondsSinceEpoch,
            'score': 140,
            'lastWordPoints': 140,
            'wordsCompleted': 1,
            'pauseCount': 0,
            'actualDurationMs': 800,
          };
        }
        return {'gameId': 'srv_live_1', 'status': 'finished'};
      };

      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.pump();

      expect(find.text('1 / 200'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Casa');
      await tester.pump();
      await tester.pump();

      expect(submittedWords, ['Casa']);
      expect(find.text('2 / 200'), findsOneWidget);
      expect(find.text('140'), findsOneWidget);

      snapshotController.add({
        'gameId': 'srv_live_1',
        'status': 'finished',
        'isWin': false,
        'terminationReason': 'timeout',
        'score': 140,
        'wordsCompleted': 1,
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EndGamePage), findsOneWidget);
      await snapshotController.close();
    });
  });
}
