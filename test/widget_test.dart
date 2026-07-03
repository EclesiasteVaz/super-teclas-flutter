import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/main.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders Super and Teclas titles', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('Super'), findsOneWidget);
      expect(find.text('Teclas'), findsOneWidget);
    });

    testWidgets('renders start button', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('Começar o jogo'), findsOneWidget);
    });

    testWidgets('tapping start button navigates to game page', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Começar o jogo'));
      await tester.pumpAndSettle();
    });
  });
}
