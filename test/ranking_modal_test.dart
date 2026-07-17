import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/ui/widgets/ranking_modal.dart';

Widget _buildApp() {
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
      home: Builder(
        builder: (context) => Scaffold(
          body: GestureDetector(
            onTap: () => RankingModal.show(context),
            child: const Text('Open Ranking'),
          ),
        ),
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

  group('RankingModal', () {
    testWidgets('opens when show is called', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Open Ranking'));
      await tester.pumpAndSettle();

      expect(find.byType(RankingModal), findsOneWidget);
    });

    testWidgets('displays ranking title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Open Ranking'));
      await tester.pumpAndSettle();

      expect(find.text('🏆 Ranking'), findsOneWidget);
    });

    testWidgets('has close button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Open Ranking'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows empty state when no rankings', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.tap(find.text('Open Ranking'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });
  });
}
