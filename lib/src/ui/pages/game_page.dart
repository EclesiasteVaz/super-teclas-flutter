import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/game_service.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:super_teclas/src/ui/widgets/footer_widget.dart';
import 'package:super_teclas/src/ui/widgets/ranking_modal.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, this.onGameEnd});

  final void Function(int? score)? onGameEnd;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool isPaused = false;
  bool _isNavigating = false;
  late Timer _timer;
  late GameService gameService;
  final _controllerInput = TextEditingController();
  final _focusNode = FocusNode();
  late int _time;
  late int _lastKnownIndex;
  StreamSubscription? _playerCompleteSubscription;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);

    gameService = GameService();
    _lastKnownIndex = gameService.currentIndex;
    _time = gameService.getTimeForWord();

    _audioPlayer.setReleaseMode(ReleaseMode.release);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _audioPlayer.setVolume(0.3);
      await _audioPlayer
          .setSource(AssetSource('audios/stranger-things-124008.mp3'));
      await _audioPlayer.resume();
      _playerCompleteSubscription =
          _audioPlayer.onPlayerComplete.listen((_) async {
        if (_isNavigating) return;
        await _audioPlayer
            .setSource(AssetSource('audios/stranger-things-124008.mp3'));
        await _audioPlayer.resume();
      });
    });

    gameService.addListener(_onGameEvent);
    _startTimer();
    _setupKeyboardHandler();
  }

  void _setupKeyboardHandler() {
    try {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
    } catch (_) {}
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _resetCurrentWord();
      return true;
    }
    return false;
  }

  void _resetCurrentWord() {
    setState(() {
      _controllerInput.clear();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_isNavigating) return;
        if (!isPaused) {
          _time--;
        }
        if (_time == 0) {
          _isNavigating = true;
          _timer.cancel();
          _audioPlayer.stop();
          widget.onGameEnd?.call(gameService.score);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EndGamePage(
                  isWin: false,
                  level: gameService.score,
                  totalWordsCompleted: gameService.totalWordsCompleted,
                  accuracy: gameService.accuracy,
                  wordTimes: gameService.wordTimes,
                  words: gameService.words,
                  averageSpeed: gameService.averageTimePerWord,
                  onGameEnd: widget.onGameEnd,
                ),
              ),
            );
          }
          return;
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _onGameEvent() {
    if (_isNavigating) return;
    if (!mounted) return;

    if (gameService.isWin) {
      _isNavigating = true;
      _timer.cancel();
      _audioPlayer.stop();
      widget.onGameEnd?.call(gameService.score);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EndGamePage(
            isWin: true,
            level: gameService.score,
            totalWordsCompleted: gameService.totalWordsCompleted,
            accuracy: gameService.accuracy,
            wordTimes: gameService.wordTimes,
            words: gameService.words,
            averageSpeed: gameService.averageTimePerWord,
            onGameEnd: widget.onGameEnd,
          ),
        ),
      );
      return;
    }

    if (gameService.currentIndex != _lastKnownIndex) {
      _controllerInput.text = '';
      _time = gameService.getTimeForWord();
    }
    _lastKnownIndex = gameService.currentIndex;
    setState(() {});
  }

  @override
  void dispose() {
    try {
      HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    } catch (_) {}
    gameService.removeListener(_onGameEvent);
    gameService.dispose();
    _timer.cancel();
    _playerCompleteSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _controllerInput.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      isPaused = true;
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed && !isPaused) {
      _audioPlayer.resume();
    }
    setState(() {});
    super.didChangeAppLifecycleState(state);
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.resume();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer.setVolume(_isMuted ? 0 : 0.3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(strings, isWide),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 20,
                  vertical: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      children: [
                        _buildMetricsHud(strings, isWide),
                        const SizedBox(height: 28),
                        _buildSessionProgress(strings),
                        const SizedBox(height: 48),
                        _buildWordPresentation(strings, isWide),
                        const SizedBox(height: 36),
                        _buildTypingInputBox(strings, isWide),
                        const SizedBox(height: 24),
                        _buildKeycapHints(strings),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppStrings strings, bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 20,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/keyboard.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strings.superTeclasTitle,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => RankingModal.show(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  strings.rankingTitle,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                tooltip: _isMuted ? strings.soundOff : strings.soundOn,
              ),
              IconButton(
                onPressed: _togglePause,
                icon: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                tooltip: strings.pause,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHud(AppStrings strings, bool isWide) {
    final points = (gameService.totalWordsCompleted * 100) + (gameService.score * 10);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.points,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatPoints(points),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: isWide ? 38 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+50',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentYellow,
              width: 5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _time.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: AppColors.accentYellow,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              strings.accuracy,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${gameService.accuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: isWide ? 38 : 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPoints(int score) {
    if (score >= 1000) {
      final thousands = score ~/ 1000;
      final remainder = (score % 1000).toString().padLeft(3, '0');
      return '$thousands.$remainder';
    }
    return score.toString();
  }

  Widget _buildSessionProgress(AppStrings strings) {
    final current = gameService.indexWordUseds.length;
    final total = gameService.words.isNotEmpty ? gameService.words.length : 200;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.session,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              '$current / $total',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildWordPresentation(AppStrings strings, bool isWide) {
    final word = gameService.currentWord.text;
    final input = _controllerInput.text;

    final spans = <TextSpan>[];
    for (var i = 0; i < word.length; i++) {
      final wordChar = word[i];
      Color color;
      if (i < input.length) {
        color = input[i] == wordChar ? AppColors.accentGreen : AppColors.accentRed;
      } else {
        color = AppColors.textPrimary;
      }
      spans.add(TextSpan(
        text: wordChar,
        style: TextStyle(
          color: color,
          fontSize: isWide ? 44 : 32,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    final difficultyText = _formatDifficulty(strings, gameService.currentWord.difficulty);
    final bonusMultiplier = _getBonusMultiplier(gameService.currentWord.difficulty);

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
            children: spans,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMetadataBadge('${strings.difficultyLabel}: $difficultyText'),
            const SizedBox(width: 10),
            _buildMetadataBadge('${strings.bonusLabel}: $bonusMultiplier'),
          ],
        ),
      ],
    );
  }

  String _formatDifficulty(AppStrings strings, String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return strings.easy;
      case 'hard':
        return strings.hard;
      default:
        return strings.medium;
    }
  }

  String _getBonusMultiplier(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return '1.0x';
      case 'hard':
        return '2.0x';
      default:
        return '1.5x';
    }
  }

  Widget _buildMetadataBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.badgeBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTypingInputBox(AppStrings strings, bool isWide) {
    return Container(
      width: isWide ? 560 : double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221884FF),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controllerInput,
              focusNode: _focusNode,
              autofocus: true,
              enabled: !isPaused,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: strings.typeWord,
                hintStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
              ),
              onChanged: (text) {
                gameService.recordKeystroke();
                if (text.isNotEmpty &&
                    text.length <= gameService.currentWord.text.length &&
                    text[text.length - 1] ==
                        gameService.currentWord.text[text.length - 1]) {
                  gameService.addCorrectKeystroke();
                }
                gameService.writing(word: text);
                setState(() {});
              },
              onFieldSubmitted: (text) {
                gameService.writing(word: text);
              },
            ),
          ),
          SvgPicture.asset(
            'assets/icons/enter.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.textMuted,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeycapHints(AppStrings strings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKeycap('ESC', strings.resetKeyHint),
        const SizedBox(width: 24),
        _buildKeycap('ENTER', strings.confirmKeyHint),
      ],
    );
  }

  Widget _buildKeycap(String keyLabel, String actionLabel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          actionLabel,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
