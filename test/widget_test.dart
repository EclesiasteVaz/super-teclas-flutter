import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';

Widget buildApp() {
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
      home: const HomePage(),
    ),
  );
}

void main() {
  group('HomePage', () {
    testWidgets('renders Super and Teclas titles', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Super'), findsOneWidget);
      expect(find.text('Teclas'), findsOneWidget);
    });

    testWidgets('renders start button', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Começar o jogo'), findsOneWidget);
    });

    testWidgets('tapping start button navigates to game page', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Começar o jogo'));
      await tester.pumpAndSettle();
    });
  });
}
