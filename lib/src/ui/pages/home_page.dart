import 'package:flutter/material.dart';
import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/services/storage_service.dart';
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
  String? _username;
  final _usernameController = TextEditingController();
  List<RankingEntry> _rankings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsername();
      _loadRankings();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final username = await StorageService.getUsername();
    if (mounted) {
      setState(() => _username = username);
    }
  }

  Future<void> _loadRankings() async {
    final rankings = await RankingService.getRankings();
    if (mounted) {
      setState(() => _rankings = rankings);
    }
  }

  Future<void> _saveUsername() async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) return;
    await StorageService.saveUsername(name);
    if (mounted) {
      setState(() => _username = name);
      _usernameController.clear();
    }
  }

  void _updateHighScore(int? score) async {
    if (mounted == false) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (score != null && score > _highScore && mounted) {
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
              const SizedBox(height: 24),
              _buildUsernameSection(strings),
              const SizedBox(height: 16),
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
              if (_rankings.isNotEmpty) _buildRankingSection(strings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameSection(AppStrings strings) {
    if (_username != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 20, color: Colors.blue[400]),
          const SizedBox(width: 8),
          Text(
            _username!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[400],
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: 300,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _usernameController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Username',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(Icons.person, color: Colors.grey[500]),
              ),
              onFieldSubmitted: (_) => _saveUsername(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _saveUsername,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
    );
  }

  Widget _buildRankingSection(AppStrings strings) {
    return Column(
      children: [
        const Divider(height: 32),
        Text(
          '🏆 Ranking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.yellow[700],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: const Color.fromARGB(85, 28, 28, 29),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (var i = 0; i < _rankings.length && i < 10; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${i + 1}.',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _rankings[i].username,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_rankings[i].score}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
