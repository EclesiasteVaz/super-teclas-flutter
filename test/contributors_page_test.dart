import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/ui/pages/contributors_page.dart';

Widget _buildApp() {
  return LocaleProvider(
    locale: const Locale('pt'),
    onLocaleChanged: (_) {},
    child: const MaterialApp(
      locale: Locale('pt'),
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt'), Locale('en')],
      home: ContributorsPage(),
    ),
  );
}

void main() {
  group('ContributorsPage', () {
    testWidgets('renders contributors title in app bar', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Colaboradores'), findsOneWidget);
    });

    testWidgets('renders main title and badge', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Colaboradores do Jogo'), findsOneWidget);
      expect(find.text('EQUIPA & COMUNIDADE OPEN SOURCE'), findsOneWidget);
    });

    testWidgets('renders current contributors names and headlines',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('Eclesiaste Vaz'), findsOneWidget);
      expect(find.text('Mobile Engineer'), findsWidgets);
      expect(find.text('Francisco Ganga'), findsOneWidget);
      expect(find.text('UI/UX Designer'), findsWidgets);
    });

    testWidgets('renders next contributor invite card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump();
      expect(find.text('Próximo Colaborador'), findsOneWidget);
      expect(find.text('Seu Lugar Aqui'), findsOneWidget);
      expect(find.text('Juntar-se ao Projeto'), findsOneWidget);
    });

    testWidgets('renders role filter chips and filters design role',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Open Source'), findsWidgets);
      expect(find.text('Design'), findsWidgets);

      await tester.tap(find.text('Design'));
      await tester.pump();
      expect(find.text('Francisco Ganga'), findsOneWidget);
      expect(find.text('Eclesiaste Vaz'), findsNothing);
    });

    testWidgets('renders call to action section', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('Quero Contribuir'), findsOneWidget);
      expect(find.text('GitHub'), findsWidgets);
    });

    testWidgets('has back button in app bar', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
