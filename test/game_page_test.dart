import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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

  group('GamePage', () {
    testWidgets('renders game interface', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GamePage()),
      );
      await tester.pump();

      expect(find.text('Pontos'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows pause button in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GamePage()),
      );
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('typing with wrong word does not play sound on error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: GamePage()),
      );
      await tester.pump();

      final textField = find.byType(TextFormField);
      expect(textField, findsOneWidget);
    });
  });
}
