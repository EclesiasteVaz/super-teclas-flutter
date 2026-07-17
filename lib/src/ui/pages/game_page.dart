import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/services/game_service.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';

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
  late int _time;
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
          .setSource(AssetSource("audios/stranger-things-124008.mp3"));
      await _audioPlayer.resume();
      _playerCompleteSubscription =
          _audioPlayer.onPlayerComplete.listen((event) async {
        if (_isNavigating) return;
        await _audioPlayer
            .setSource(AssetSource("audios/stranger-things-124008.mp3"));
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
      _togglePause();
      return true;
    }
    return false;
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
            Navigator.of(context).pushReplacement(MaterialPageRoute(
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
            ));
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(
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
      ));
      return;
    }

    if (gameService.currentIndex != _lastKnownIndex) {
      _controllerInput.text = '';
      _time = gameService.getTimeForWord();
    }
    _lastKnownIndex = gameService.currentIndex;
    setState(() {});
  }

  late int _lastKnownIndex;

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
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _toggleMute,
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
            ),
            tooltip: _isMuted ? strings.soundOff : strings.soundOn,
          ),
          IconButton(
            onPressed: _togglePause,
            icon: Icon(!isPaused ? Icons.pause : Icons.play_arrow),
            tooltip: strings.pause,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 24,
        ),
        child: Column(
          children: [
            _buildScoreAndTimer(strings, isWide),
            const SizedBox(height: 24),
            _buildWordDisplay(strings, isWide),
            const SizedBox(height: 20),
            _buildTimerProgress(),
            const SizedBox(height: 24),
            _buildInputField(strings, isWide),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreAndTimer(AppStrings strings, bool isWide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              gameService.score.toString(),
              style: const TextStyle(fontSize: 24),
            ),
            Text(strings.points),
          ],
        ),
        SizedBox(
          width: 85,
          height: 85,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 75,
                height: 75,
                child: CircularProgressIndicator(
                  value: _time / gameService.getTimeForWord(),
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _time > 5
                        ? Colors.green
                        : _time > 3
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              Text(
                _time.toString(),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _time > 5
                      ? Colors.green
                      : _time > 3
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 80),
      ],
    );
  }

  Widget _buildWordDisplay(AppStrings strings, bool isWide) {
    final word = gameService.currentWord.text;
    final input = _controllerInput.text;

    final spans = <TextSpan>[];
    for (var i = 0; i < word.length; i++) {
      final wordChar = word[i];
      Color color;
      if (i < input.length) {
        color = input[i] == wordChar ? Colors.green : Colors.red;
      } else {
        color = Colors.white;
      }
      spans.add(TextSpan(
        text: wordChar,
        style: TextStyle(color: color, fontSize: isWide ? 36 : 28),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        children: spans,
      ),
    );
  }

  Widget _buildTimerProgress() {
    final totalWords = gameService.words.length;
    final currentProgress = gameService.indexWordUseds.length;
    final progress = currentProgress / totalWords;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(
            '$currentProgress / $totalWords',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(AppStrings strings, bool isWide) {
    return SizedBox(
      width: isWide ? 400 : double.infinity,
      child: TextFormField(
        maxLines: 1,
        enableSuggestions: false,
        autofocus: true,
        autocorrect: false,
        enabled: !isPaused,
        controller: _controllerInput,
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
        decoration: InputDecoration(
          hintText: strings.typeWord,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  int impressLevel() {
    return gameService.score;
  }
}
