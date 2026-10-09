import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/services/ranking_service.dart';
import 'package:super_teclas/src/services/storage_service.dart';
import 'package:super_teclas/src/ui/pages/dictionary_page.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';
import 'package:super_teclas/src/ui/widgets/button_custom_widget.dart';

class EndGamePage extends StatefulWidget {
  const EndGamePage({
    super.key,
    required this.isWin,
    required this.level,
    this.onGameEnd,
    this.totalWordsCompleted = 0,
    this.accuracy = 0,
    this.wordTimes = const {},
    this.words = const [],
    this.averageSpeed = 0,
  });

  final bool isWin;
  final int level;
  final void Function(int? score)? onGameEnd;
  final int totalWordsCompleted;
  final double accuracy;
  final Map<int, double> wordTimes;
  final List<WordModel> words;
  final double averageSpeed;

  @override
  State<EndGamePage> createState() => _EndGamePageState();
}

class _EndGamePageState extends State<EndGamePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  AudioPlayer audioPlayer = AudioPlayer();
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;
  final _confettiParticles = <_ConfettiParticle>[];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConfetti();
    _navigateTo = _navigateToImpl;
    _submitRanking();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isWin) {
        await audioPlayer.setSource(AssetSource(
            "audios/brass-fanfare-with-timpani-and-winchimes-reverberated-146260.mp3"));
        _confettiController.forward();
      } else {
        await audioPlayer.setSource(AssetSource("audios/fail-144746.mp3"));
      }
      await audioPlayer.resume();
    });
  }

  Future<void> _submitRanking() async {
    final username = await StorageService.getUsername();
    if (username == null) {
      debugPrint('[EndGamePage] Username not set, skipping ranking');
      return;
    }

    debugPrint(
      '[EndGamePage] Submitting ranking for $username: '
      'score=${widget.level}, words=${widget.totalWordsCompleted}, '
      'accuracy=${widget.accuracy}',
    );

    await RankingService.submitScore(
      username: username,
      score: widget.level,
      wordsCompleted: widget.totalWordsCompleted,
      accuracy: widget.accuracy,
      averageSpeed: widget.averageSpeed,
    );
  }

  void _setupConfetti() {
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
    for (var i = 0; i < 60; i++) {
      _confettiParticles.add(_ConfettiParticle(_random));
    }
    _confettiController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      audioPlayer.resume();
    }
    super.didChangeAppLifecycleState(state);
  }

  late void Function(Widget page) _navigateTo;

  void _navigateToImpl(Widget page) {
    audioPlayer.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final isNewBest = widget.level == 100;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              audioPlayer.stop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DictionaryPage(),
                ),
              );
            },
            icon: const Icon(Icons.book),
            tooltip: strings.dictionary,
          ),
          IconButton(
            onPressed: () => _navigateTo(const HomePage()),
            icon: const Icon(Icons.home),
            tooltip: strings.home,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (widget.isWin) _buildConfetti(),
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 16,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isWide ? 200 : 150,
                      height: isWide ? 200 : 150,
                      child: Image.asset("assets/images/app_icon.png"),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isWin ? strings.youWin : strings.youLose,
                      style: TextStyle(
                        fontSize: isWide ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color:
                            widget.isWin ? Colors.green[500] : Colors.red[500],
                      ),
                    ),
                    if (isNewBest)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          strings.newBest,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.yellow[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildScoreCard(strings, isWide),
                    if (widget.wordTimes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSpeedStats(strings, isWide),
                    ],
                    const SizedBox(height: 24),
                    ButtonCustomWidget(
                      onPressed: () => _navigateTo(const GamePage()),
                      text: strings.restart,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _navigateTo(const HomePage()),
                      child: Text(strings.home),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(AppStrings strings, bool isWide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color.fromARGB(85, 28, 28, 29),
        child: SizedBox(
          width: isWide ? 300 : 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              children: [
                Text(
                  widget.level.toString(),
                  style: TextStyle(
                    fontSize: isWide ? 48 : 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  strings.scorePoints,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedStats(AppStrings strings, bool isWide) {
    final avg = widget.averageSpeed;
    final fastest = widget.wordTimes.entries.isNotEmpty
        ? widget.wordTimes.entries.reduce((a, b) => a.value <= b.value ? a : b)
        : null;
    final slowest = widget.wordTimes.entries.isNotEmpty
        ? widget.wordTimes.entries.reduce((a, b) => a.value >= b.value ? a : b)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color.fromARGB(85, 28, 28, 29),
        child: SizedBox(
          width: isWide ? 300 : 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Text(
                  strings.typingSpeed,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${strings.averageTime}: ${avg.toStringAsFixed(1)}${strings.secondsUnit}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (fastest != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${strings.fastestWord}: ${widget.words[fastest.key].text} (${fastest.value.toStringAsFixed(1)}${strings.secondsUnit})',
                    style: TextStyle(fontSize: 13, color: Colors.green[400]),
                  ),
                ],
                if (slowest != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${strings.slowestWord}: ${widget.words[slowest.key].text} (${slowest.value.toStringAsFixed(1)}${strings.secondsUnit})',
                    style: TextStyle(fontSize: 13, color: Colors.orange[400]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _confettiAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _confettiParticles,
                progress: _confettiAnimation.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double rotation;

  _ConfettiParticle(Random random)
      : x = random.nextDouble(),
        y = -random.nextDouble() * 0.5,
        speed = 0.3 + random.nextDouble() * 0.4,
        size = 4 + random.nextDouble() * 6,
        color = Color.fromARGB(
          255,
          random.nextInt(200) + 55,
          random.nextInt(200) + 55,
          random.nextInt(200) + 55,
        ),
        rotation = random.nextDouble() * 2 * pi;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    for (final p in particles) {
      final currentY = (p.y + progress * p.speed) * size.height;
      if (currentY > size.height) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 1 - progress * 0.5);

      canvas.save();
      canvas.translate(p.x * size.width, currentY);
      canvas.rotate(p.rotation + progress * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
