import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/ui/widgets/daily_goal_card.dart';
import 'package:super_teclas/src/ui/widgets/footer_widget.dart';
import 'package:super_teclas/src/ui/widgets/game_mode_cards.dart';
import 'package:super_teclas/src/ui/widgets/global_activity_card.dart';
import 'package:super_teclas/src/ui/widgets/nav_header_widget.dart';
import 'package:super_teclas/src/ui/widgets/ranking_card.dart';

Widget _buildTestWrapper(Widget child) {
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('NavHeaderWidget', () {
    testWidgets('renders brand title', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const NavHeaderWidget()));
      expect(find.text('Super Teclas'), findsOneWidget);
    });

    testWidgets('renders ranking button', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const NavHeaderWidget()));
      expect(find.text('Ranking'), findsOneWidget);
    });
  });

  group('FooterWidget', () {
    testWidgets('renders copyright tagline', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const FooterWidget()));
      expect(
        find.text('© 2024 Super Teclas. Alta Performance em Digitação.'),
        findsOneWidget,
      );
    });

    testWidgets('renders social links', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const FooterWidget()));
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });
  });

  group('DailyGoalCard', () {
    testWidgets('renders daily goal count and percentage', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(
        const DailyGoalCard(wordsCount: 750, percentage: 85),
      ));
      expect(find.text('Meta Diária'), findsOneWidget);
      expect(find.text('750'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });
  });

  group('GameModeCards', () {
    testWidgets('renders Time Trial and Sudden Death cards', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const GameModeCards()));
      expect(find.text('Time Trial'), findsOneWidget);
      expect(find.text('Sudden Death'), findsOneWidget);
    });
  });

  group('GlobalActivityCard', () {
    testWidgets('renders global activity title and items', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const GlobalActivityCard()));
      expect(find.text('Atividade Global'), findsOneWidget);
      expect(find.text('heliodr'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
    });
  });

  group('RankingCard', () {
    testWidgets('renders fallback ranking rows when empty', (tester) async {
      await tester.pumpWidget(_buildTestWrapper(const RankingCard(rankings: [])));
      expect(find.text('Ranking'), findsOneWidget);
      expect(find.text('Amarildo'), findsOneWidget);
      expect(find.text('Ver ranking completo'), findsOneWidget);
    });
  });
}
