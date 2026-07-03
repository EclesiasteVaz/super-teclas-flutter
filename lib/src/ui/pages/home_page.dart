import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';
import 'package:super_teclas/src/ui/widgets/button_costum_widget.dart';
import 'package:super_teclas/src/ui/widgets/title_game_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highScore = 0;

  void _updateHighScore(int? score) {
    if (score != null && score > _highScore) {
      setState(() => _highScore = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    LocaleProvider? localeProvider;
    try {
      localeProvider = LocaleProvider.of(context);
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (localeProvider != null)
            PopupMenuButton<Locale>(
              icon: const Icon(Icons.language),
              tooltip: strings.language,
              onSelected: localeProvider.onLocaleChanged,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: const Locale('pt'),
                  child: Text(strings.portuguese),
                ),
                PopupMenuItem(
                  value: const Locale('en'),
                  child: Text(strings.english),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TitleGameWidget(fontSize: 40),
              const SizedBox(height: 24),
              Text(
                strings.instructions,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${strings.pressEnter}  •  ${strings.pressEsc}  •  ${strings.pressM}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ButtonCostumWidget(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => GamePage(
                        onGameEnd: _updateHighScore,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_highScore > 0)
                Column(
                  children: [
                    Text(
                      '${strings.bestScore}: $_highScore%',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
