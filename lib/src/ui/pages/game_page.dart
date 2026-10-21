import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/data/models/game_session_model.dart';
import 'package:super_teclas/src/services/game_service.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/services/storage_service.dart';
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
  bool _isHandlingTimeout = false;
  late Timer _timer;
  late GameService gameService;
  final _controllerInput = TextEditingController();
  final _focusNode = FocusNode();
  late int _time;
  late int _lastKnownIndex;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription<ServerGameStepResult>? _gameSessionSubscription;
  bool _isMuted = false;
  String _userId = 'anonymous';
  String _username = '';

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
      _initRemoteGameSession();
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

  Future<void> _initRemoteGameSession() async {
    final sessionId = await StorageService.getOrCreateSessionId();
    final storedUser = await RankingService.getSessionUsername();
    final uid = await RankingService.ensureAuthenticatedUser();
    _userId = uid.isNotEmpty ? uid : sessionId;
    _username = storedUser ?? '';
    final previousWordText = gameService.currentWord.text;

    final stepResult = await RankingService.startServerGameSession(
      languageCode: gameService.languageCode,
      username: _username,
      initialWordId: gameService.currentWord.id,
    );
    if (!mounted || _isNavigating) return;

    if (stepResult != null && stepResult.gameId.isNotEmpty) {
      gameService.applyServerStart(stepResult);
      _lastKnownIndex = gameService.currentIndex;
      if (stepResult.currentWord?.text != previousWordText) {
        _controllerInput.clear();
      }
      _time = gameService.getTimeForWord();

      await _gameSessionSubscription?.cancel();
      _gameSessionSubscription = RankingService.watchGameSession(
        gameId: stepResult.gameId,
        languageCode: gameService.languageCode,
      )?.listen(_onRemoteGameSnapshot);

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onRemoteGameSnapshot(ServerGameStepResult snapshot) {
    if (_isNavigating || !mounted) return;

    if (snapshot.status == GameStatus.finished) {
      gameService.applyServerStep(snapshot);
      _navigateToEndGame(isWin: snapshot.isWin);
    }
  }

  void _navigateToEndGame({required bool isWin}) {
    if (_isNavigating) return;
    _isNavigating = true;
    gameService.finishGame(win: isWin);
    _timer.cancel();
    _gameSessionSubscription?.cancel();
    _audioPlayer.stop();
    widget.onGameEnd?.call(gameService.score);

    if (!mounted) return;
    final session = gameService.toSessionModel(
      userId: _userId,
      username: _username,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EndGamePage(
          isWin: isWin,
          level: gameService.score,
          totalWordsCompleted: gameService.totalWordsCompleted,
          accuracy: gameService.accuracy,
          wordTimes: gameService.wordTimes,
          words: gameService.words,
          averageSpeed: gameService.averageTimePerWord,
          gameSession: session,
          onGameEnd: widget.onGameEnd,
        ),
      ),
    );
  }

  void _setupKeyboardHandler() {
    try {
      HardwareKeyboard.instance.addHandler(_onKeyEvent);
    } catch (_) {}
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (!gameService.isRunning || gameService.isSubmittingWord) return true;
      _resetCurrentWord();
      return true;
    }
    return false;
  }

  void _resetCurrentWord() {
    if (!gameService.isRunning || gameService.isSubmittingWord) return;
    setState(() {
      _controllerInput.clear();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_isNavigating || _isHandlingTimeout) return;
        if (gameService.isRunning && !gameService.isSubmittingWord) {
          if (gameService.isServerAuthoritative &&
              gameService.wordDeadlineAt != null) {
            _time = gameService.getRemainingSecondsFromDeadline();
          } else {
            _time--;
          }
        }
        if (_time <= 0 && !gameService.isSubmittingWord) {
          if (gameService.isServerAuthoritative &&
              gameService.gameId != null &&
              gameService.gameId!.isNotEmpty) {
            _handleServerTimeout();
          } else {
            _navigateToEndGame(isWin: false);
          }
          return;
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _handleServerTimeout() async {
    if (_isNavigating || _isHandlingTimeout) return;
    _isHandlingTimeout = true;
    try {
      final activeGameId = gameService.gameId;
      if (activeGameId != null && activeGameId.isNotEmpty) {
        final result = await RankingService.timeoutGameOnServer(
          gameId: activeGameId,
          wordSequence: gameService.wordSequence,
          accuracy: gameService.accuracy,
          languageCode: gameService.languageCode,
        );
        if (!mounted || _isNavigating) return;
        if (result != null) {
          gameService.applyServerStep(result);
          if (_isNavigating) return;
          if (result.status != GameStatus.finished) {
            _time = gameService.getTimeForWord();
            setState(() {});
            return;
          }
        }
      }
      if (mounted && !_isNavigating) {
        _navigateToEndGame(isWin: false);
      }
    } finally {
      _isHandlingTimeout = false;
    }
  }

  Future<void> _submitWordToServer(String typedWord) async {
    if (_isNavigating ||
        !gameService.isRunning ||
        gameService.isSubmittingWord) {
      return;
    }
    final activeGameId = gameService.gameId;
    if (activeGameId == null || activeGameId.isEmpty) {
      gameService.writing(word: typedWord);
      return;
    }

    setState(() {
      gameService.isSubmittingWord = true;
    });

    final result = await RankingService.submitWordToServer(
      gameId: activeGameId,
      word: typedWord,
      accuracy: gameService.accuracy,
      languageCode: gameService.languageCode,
    );

    if (!mounted || _isNavigating) return;

    if (result == null) {
      setState(() {
        gameService.isSubmittingWord = false;
      });
      return;
    }

    gameService.applyServerStep(result);
    if (_isNavigating) return;

    if (result.status == GameStatus.finished) {
      _navigateToEndGame(isWin: result.isWin);
      return;
    }

    _controllerInput.clear();
    _lastKnownIndex = gameService.currentIndex;
    _time = gameService.getTimeForWord();
    setState(() {});
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isNavigating && gameService.isRunning) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onGameEvent() {
    if (_isNavigating) return;
    if (!mounted) return;

    if (gameService.isWin || gameService.isFinished) {
      _navigateToEndGame(isWin: gameService.isWin);
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
    _gameSessionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _controllerInput.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(context).languageCode;
    gameService.setLanguage(localeCode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (gameService.isRunning && gameService.canPause) {
        gameService.pauseGame();
        isPaused = gameService.isPaused;
        _focusNode.unfocus();
        _syncRemoteGameState();
      }
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed && !gameService.isPaused) {
      _audioPlayer.resume();
    }
    setState(() {});
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _togglePause() async {
    if (gameService.isFinished || gameService.isSubmittingWord) return;

    final activeGameId = gameService.gameId;
    if (gameService.isServerAuthoritative &&
        activeGameId != null &&
        activeGameId.isNotEmpty) {
      if (gameService.isPaused) {
        setState(() {
          gameService.resumeGame();
          isPaused = false;
          _audioPlayer.resume();
          _focusNode.requestFocus();
        });
        final result = await RankingService.resumeGameOnServer(
          gameId: activeGameId,
          languageCode: gameService.languageCode,
        );
        if (!mounted || _isNavigating || result == null) return;
        gameService.applyServerStep(result);
        if (result.status == GameStatus.finished) {
          _navigateToEndGame(isWin: result.isWin);
        } else {
          setState(() {
            isPaused = gameService.isPaused;
            _time = gameService.getTimeForWord();
          });
        }
      } else if (gameService.canPause) {
        setState(() {
          gameService.pauseGame();
          isPaused = true;
          _audioPlayer.pause();
          _focusNode.unfocus();
        });
        final result = await RankingService.pauseGameOnServer(
          gameId: activeGameId,
          languageCode: gameService.languageCode,
        );
        if (!mounted || _isNavigating || result == null) return;
        gameService.applyServerStep(result);
        if (result.status == GameStatus.finished) {
          _navigateToEndGame(isWin: result.isWin);
        } else {
          setState(() {
            isPaused = gameService.isPaused;
            _time = gameService.getTimeForWord();
          });
        }
      }
      return;
    }

    var changed = false;
    setState(() {
      if (gameService.isPaused) {
        changed = gameService.resumeGame();
        isPaused = false;
        _audioPlayer.resume();
        _focusNode.requestFocus();
      } else if (gameService.canPause) {
        changed = gameService.pauseGame();
        isPaused = true;
        _audioPlayer.pause();
        _focusNode.unfocus();
      }
    });

    if (changed) {
      _syncRemoteGameState();
    }
  }

  void _syncRemoteGameState() {
    final activeGameId = gameService.gameId;
    if (activeGameId != null && activeGameId.isNotEmpty) {
      RankingService.syncGameSessionState(
        gameId: activeGameId,
        status: gameService.status,
        pauseCount: gameService.pauseCount,
        totalPausedDurationMs: gameService.totalPausedDurationMs,
        wordsCompleted: gameService.totalWordsCompleted,
        score: gameService.score,
      );
    }
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
    final statusLabel = gameService.isPaused
        ? strings.gamePausedStatus
        : gameService.isFinished
            ? strings.gameFinishedStatus
            : strings.gameRunningStatus;
    final statusColor = gameService.isPaused
        ? AppColors.accentYellow
        : gameService.isFinished
            ? AppColors.accentRed
            : AppColors.accentGreen;

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
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withAlpha(90)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
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
                onPressed:
                    (gameService.isPaused || gameService.canPause)
                        ? _togglePause
                        : null,
                icon: Icon(
                  gameService.isPaused ? Icons.play_arrow : Icons.pause,
                  color: (gameService.isPaused || gameService.canPause)
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                  size: 22,
                ),
                tooltip:
                    '${strings.pause} (${gameService.remainingPauses}/${GameService.maxPauses})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsHud(AppStrings strings, bool isWide) {
    final points = gameService.score;
    final deltaPoints = gameService.lastWordPoints > 0
        ? gameService.lastWordPoints
        : gameService.currentWord.basePoints;

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
                Text(
                  '+$deltaPoints',
                  style: const TextStyle(
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
    final total = gameService.sessionTotalWords;
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
      final wordChar = gameService.isPaused ? '•' : word[i];
      Color color;
      if (gameService.isPaused) {
        color = AppColors.textMuted;
      } else if (i < input.length) {
        color =
            input[i] == wordChar ? AppColors.accentGreen : AppColors.accentRed;
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

    final difficultyText =
        _formatDifficulty(strings, gameService.currentWord.difficulty);
    final bonusMultiplier =
        _getBonusMultiplier(gameService.currentWord.difficulty);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: gameService.isPaused ? 8 : 0,
                sigmaY: gameService.isPaused ? 8 : 0,
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                  children: spans,
                ),
              ),
            ),
            if (gameService.isPaused)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentYellow),
                ),
                child: Text(
                  strings.pausedWordHidden,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentYellow,
                  ),
                ),
              ),
          ],
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
              enabled: gameService.isRunning,
              readOnly: gameService.isSubmittingWord,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: gameService.isPaused
                    ? strings.pausedWordHidden
                    : strings.typeWord,
                hintStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
              ),
              onChanged: (text) {
                if (!gameService.isRunning || gameService.isSubmittingWord) {
                  return;
                }
                gameService.recordKeystroke();
                if (text.isNotEmpty &&
                    text.length <= gameService.currentWord.text.length &&
                    text[text.length - 1] ==
                        gameService.currentWord.text[text.length - 1]) {
                  gameService.addCorrectKeystroke();
                }
                if (gameService.isServerAuthoritative) {
                  setState(() {});
                  if (text.trim() == gameService.currentWord.text) {
                    _submitWordToServer(text.trim());
                  }
                  return;
                }
                gameService.writing(word: text);
                setState(() {});
              },
              onFieldSubmitted: (text) {
                if (!gameService.isRunning || gameService.isSubmittingWord) {
                  return;
                }
                if (gameService.isServerAuthoritative) {
                  if (text.trim() == gameService.currentWord.text) {
                    _submitWordToServer(text.trim());
                  }
                  return;
                }
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
