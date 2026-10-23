import 'dart:async';

import 'package:flutter/material.dart';

import 'package:super_teclas/main.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/services/storage_service.dart';
import 'package:super_teclas/src/ui/pages/contributors_page.dart';
import 'package:super_teclas/src/ui/pages/dictionary_page.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:super_teclas/src/ui/widgets/daily_goal_card.dart';
import 'package:super_teclas/src/ui/widgets/footer_widget.dart';
import 'package:super_teclas/src/ui/widgets/game_mode_cards.dart';
import 'package:super_teclas/src/ui/widgets/global_activity_card.dart';
import 'package:super_teclas/src/ui/widgets/nav_header_widget.dart';
import 'package:super_teclas/src/ui/widgets/ranking_card.dart';
import 'package:super_teclas/src/ui/widgets/ranking_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _highScore = 0;
  String? _username;
  bool _isSavingUsername = false;
  final _usernameController = TextEditingController();
  List<RankingEntry> _rankings = [];
  List<RankingEntry> _recentGames = [];
  StreamSubscription<List<RankingEntry>>? _rankingsSubscription;
  StreamSubscription<List<RankingEntry>>? _recentGamesSubscription;
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsername();
      _loadRankings();
      _subscribeToRankings();
    });
  }

  @override
  void dispose() {
    _rankingsSubscription?.cancel();
    _recentGamesSubscription?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    await StorageService.getOrCreateSessionId();
    final storedHighScore = await StorageService.getHighScore();
    final username = await RankingService.getSessionUsername();
    if (mounted) {
      setState(() {
        _highScore = storedHighScore;
        _username = username;
        if (username != null && _usernameController.text.trim().isEmpty) {
          _usernameController.text = username;
        }
      });
    }
  }

  Future<void> _syncHighScoreFromEntries(List<RankingEntry> entries) async {
    final currentUser = _username?.trim().toLowerCase() ?? '';
    if (currentUser.isEmpty) return;
    for (final entry in entries) {
      if (entry.username.trim().toLowerCase() == currentUser &&
          entry.score > _highScore) {
        await StorageService.saveHighScore(entry.score);
        if (mounted) {
          setState(() => _highScore = entry.score);
        }
        break;
      }
    }
  }

  Future<void> _loadRankings() async {
    final rankings = await RankingService.getRankings();
    final recentGames = await RankingService.getRecentGames(limit: 2);
    if (mounted) {
      setState(() {
        _rankings = rankings;
        _recentGames = recentGames;
      });
      await _syncHighScoreFromEntries(rankings);
    }
  }

  void _subscribeToRankings() {
    if (!RankingService.isAvailable) return;
    _rankingsSubscription?.cancel();
    _rankingsSubscription = RankingService.watchRankings()?.listen((entries) {
      if (mounted) {
        setState(() => _rankings = entries);
        _syncHighScoreFromEntries(entries);
      }
    });
    _recentGamesSubscription?.cancel();
    _recentGamesSubscription =
        RankingService.watchRecentGames(limit: 2)?.listen((entries) {
      if (mounted) {
        setState(() => _recentGames = entries);
      }
    });
  }

  Future<bool> _saveUsername({bool showSavedSnackBar = true}) async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) return true;
    if (_isSavingUsername) return false;

    _isSavingUsername = true;
    try {
      final strings = AppStrings.from(context);
      final saved = await RankingService.registerUsernameForSession(name);
      if (!saved) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.usernameTaken)),
          );
        }
        return false;
      }

      if (mounted) {
        setState(() => _username = name);
        if (showSavedSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.save)),
          );
        }
      }
      await _loadRankings();
      return true;
    } finally {
      _isSavingUsername = false;
    }
  }

  void _updateHighScore(int? score) async {
    if (score != null && score > 0) {
      await StorageService.saveHighScore(score);
    }
    if (mounted == false) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (score != null && score > _highScore && mounted) {
      setState(() => _highScore = score);
    }
  }

  Future<void> _startGame() async {
    final pendingName = _usernameController.text.trim();
    if (pendingName.isNotEmpty) {
      final ok = await _saveUsername(showSavedSnackBar: false);
      if (!ok || !mounted) return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GamePage(
          onGameEnd: _updateHighScore,
        ),
      ),
    );
  }

  void _openDictionary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DictionaryPage(),
      ),
    );
  }

  void _openContributors() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContributorsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            NavHeaderWidget(
              onDictionaryTap: _openDictionary,
              onContributorsTap: _openContributors,
              currentRoute: 'home',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(strings, isWide),
                    const SizedBox(height: 36),
                    _buildDashboardSection(strings, isWide),
                    const SizedBox(height: 60),
                    FooterWidget(
                      onContributorsTap: _openContributors,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(strings),
    );
  }

  Widget _buildHeroSection(AppStrings strings, bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 20,
        vertical: 32,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Super',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: isWide ? 48 : 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Teclas',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: isWide ? 48 : 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.instructionsLine1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.instructionsLine2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.accentYellow,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.pressEnter}   •   ${strings.pressEsc}   •   ${strings.pressM}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileInput(strings, isWide),
          const SizedBox(height: 16),
          _buildStartGameButton(strings, isWide),
        ],
      ),
    );
  }

  Widget _buildProfileInput(AppStrings strings, bool isWide) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: isWide
          ? Row(
              children: [
                Expanded(
                  child: _buildUsernameTextField(),
                ),
                const SizedBox(width: 10),
                _buildSaveProfileButton(strings),
              ],
            )
          : Column(
              children: [
                _buildUsernameTextField(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _buildSaveProfileButton(strings),
                ),
              ],
            ),
    );
  }

  Widget _buildUsernameTextField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: _usernameController,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          hintText: 'Username...',
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            color: AppColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.person_outline,
            size: 18,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (_) => _saveUsername(),
      ),
    );
  }

  Widget _buildSaveProfileButton(AppStrings strings) {
    return ElevatedButton.icon(
      onPressed: _saveUsername,
      icon: const Icon(Icons.check, size: 16),
      label: Text(
        strings.saveProfile,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        minimumSize: const Size(140, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    );
  }

  Widget _buildStartGameButton(AppStrings strings, bool isWide) {
    return ElevatedButton.icon(
      onPressed: _startGame,
      icon: const Icon(Icons.play_arrow, size: 20),
      label: Text(
        strings.startGame,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        minimumSize: Size(isWide ? 380 : double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDashboardSection(AppStrings strings, bool isWide) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1040),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: RankingCard(rankings: _rankings),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      const DailyGoalCard(),
                      const SizedBox(height: 16),
                      GameModeCards(
                        onTimeTrialTap: _startGame,
                        onSuddenDeathTap: _startGame,
                      ),
                      const SizedBox(height: 16),
                      GlobalActivityCard(recentGames: _recentGames),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                RankingCard(rankings: _rankings),
                const SizedBox(height: 16),
                const DailyGoalCard(),
                const SizedBox(height: 16),
                GameModeCards(
                  onTimeTrialTap: _startGame,
                  onSuddenDeathTap: _startGame,
                ),
                const SizedBox(height: 16),
                GlobalActivityCard(recentGames: _recentGames),
              ],
            ),
    );
  }

  Widget _buildBottomNavigationBar(AppStrings strings) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          if (index == 1) {
            _startGame();
          } else if (index == 2) {
            RankingModal.show(context);
          } else if (index == 3) {
            _showSettingsSheet();
          }
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: strings.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_esports_outlined),
            activeIcon: const Icon(Icons.sports_esports),
            label: strings.play,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: strings.leaderboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: strings.settings,
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    final strings = AppStrings.from(context);
    LocaleProvider? localeProvider;
    try {
      localeProvider = LocaleProvider.of(context);
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.settings,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.book, color: AppColors.primary),
                  title: Text(strings.dictionary,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openDictionary();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: AppColors.primary),
                  title: Text(strings.contributors,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openContributors();
                  },
                ),
                if (localeProvider != null) ...[
                  ListTile(
                    leading:
                        const Icon(Icons.language, color: AppColors.primary),
                    title: Text(strings.portuguese,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: localeProvider.locale.languageCode == 'pt'
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      localeProvider!.onLocaleChanged(const Locale('pt'));
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.language, color: AppColors.primary),
                    title: Text(strings.english,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: localeProvider.locale.languageCode == 'en'
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      localeProvider!.onLocaleChanged(const Locale('en'));
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
