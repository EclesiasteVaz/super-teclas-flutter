import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';

MaterialApp _buildApp(Widget home) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: const [
      ...GlobalMaterialLocalizations.delegates,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt'), Locale('en')],
    home: home,
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

  group('EndGamePage - Win', () {
    testWidgets('shows Ganhaste o jogo when isWin is true', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: true, level: 85)));
      await tester.pump();
      expect(find.text('Ganhaste o jogo!'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
    });

    testWidgets('shows Recomeçar button', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: true, level: 50)));
      await tester.pump();
      expect(find.text('Recomeçar'), findsOneWidget);
    });

    testWidgets('shows home button', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: true, level: 50)));
      await tester.pump();
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });

  group('EndGamePage - Lose', () {
    testWidgets('shows Perdeste when isWin is false', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: false, level: 30)));
      await tester.pump();
      expect(find.text('Perdeste!'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('shows Recomeçar button when lost', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: false, level: 10)));
      await tester.pump();
      expect(find.text('Recomeçar'), findsOneWidget);
    });

    testWidgets('does not show Ganhaste when lost', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: false, level: 10)));
      await tester.pump();
      expect(find.text('Ganhaste o jogo!'), findsNothing);
    });

    testWidgets('does not show Perdeste when won', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: true, level: 100)));
      await tester.pump();
      expect(find.text('Perdeste!'), findsNothing);
    });
  });

  group('EndGamePage - Home Navigation', () {
    testWidgets('tapping home icon navigates to home page', (tester) async {
      await tester.pumpWidget(_buildApp(const EndGamePage(isWin: false, level: 20)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.text('Super'), findsOneWidget);
      expect(find.text('Teclas'), findsOneWidget);
    });
  });
}
