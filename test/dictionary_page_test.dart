import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';
import 'package:super_teclas/src/ui/pages/dictionary_page.dart';

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
      home: const DictionaryPage(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await WordBank.load(languageCode: 'pt');
  });

  group('DictionaryPage', () {
    testWidgets('renders dictionary title', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Dicionário'), findsOneWidget);
    });

    testWidgets('renders search field', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders filter chips', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Fácil'), findsOneWidget);
      expect(find.text('Médio'), findsOneWidget);
      expect(find.text('Difícil'), findsOneWidget);
    });

    testWidgets('shows words in list', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('search filters words by text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Casa');
      await tester.pump();
      expect(find.widgetWithText(Card, 'Casa'), findsOneWidget);
    });

    testWidgets('search filters words by definition', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'moram');
      await tester.pump();
      expect(find.widgetWithText(Card, 'Casa'), findsOneWidget);
    });

    testWidgets('shows empty state when no results', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pump();
      expect(find.text('Nenhuma palavra encontrada'), findsOneWidget);
    });

    testWidgets('shows AppBar', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
