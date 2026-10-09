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
import 'package:super_teclas/src/ui/theme/app_colors.dart';
import 'package:super_teclas/src/ui/widgets/button_custom_widget.dart';
import 'package:super_teclas/src/ui/widgets/footer_widget.dart';

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
    final isWide = screenWidth > 720;
    final isNewBest = widget.level == 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            icon: const Icon(Icons.book, color: AppColors.textSecondary),
            tooltip: strings.dictionary,
          ),
          IconButton(
            onPressed: () => _navigateTo(const HomePage()),
            icon: const Icon(Icons.home, color: AppColors.textSecondary),
            tooltip: strings.home,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (widget.isWin) _buildConfetti(),
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 40 : 16,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildHeroStatus(strings, isNewBest),
                      const SizedBox(height: 24),
                      _buildScoreDashboard(strings, isWide),
                      if (widget.wordTimes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSpeedStatsCard(strings),
                      ],
                      const SizedBox(height: 32),
                      _buildActionButtons(strings),
                      const SizedBox(height: 48),
                      const FooterWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatus(AppStrings strings, bool isNewBest) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: widget.isWin
                ? AppColors.accentGreen.withAlpha(25)
                : AppColors.accentRed.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isWin
                  ? AppColors.accentGreen.withAlpha(90)
                  : AppColors.accentRed.withAlpha(90),
              width: 2,
            ),
          ),
          child: Icon(
            widget.isWin ? Icons.emoji_events : Icons.timer_off_outlined,
            size: 44,
            color: widget.isWin ? AppColors.accentGreen : AppColors.accentRed,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.isWin ? strings.youWin : strings.youLose,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: widget.isWin ? AppColors.accentGreen : AppColors.accentRed,
          ),
        ),
        if (isNewBest)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentYellow.withAlpha(90)),
              ),
              child: Text(
                '★ ${strings.newBest}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentYellow,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScoreDashboard(AppStrings strings, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.level.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            strings.scorePoints,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Precisão',
                  value: '${widget.accuracy.toStringAsFixed(0)}%',
                  color: AppColors.accentGreen,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceBorder),
              Expanded(
                child: _buildMetricItem(
                  label: 'Palavras',
                  value: '${widget.totalWordsCompleted}',
                  color: AppColors.primary,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.surfaceBorder),
              Expanded(
                child: _buildMetricItem(
                  label: 'Tempo Médio',
                  value: '${widget.averageSpeed.toStringAsFixed(1)}${strings.secondsUnit}',
                  color: AppColors.accentYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedStatsCard(AppStrings strings) {
    final avg = widget.averageSpeed;
    final fastest = widget.wordTimes.entries.isNotEmpty
        ? widget.wordTimes.entries.reduce((a, b) => a.value <= b.value ? a : b)
        : null;
    final slowest = widget.wordTimes.entries.isNotEmpty
        ? widget.wordTimes.entries.reduce((a, b) => a.value >= b.value ? a : b)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                strings.typingSpeed,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.averageTime}: ${avg.toStringAsFixed(1)}${strings.secondsUnit}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (fastest != null && fastest.key < widget.words.length) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentGreen.withAlpha(70)),
              ),
              child: Text(
                '${strings.fastestWord}: ${widget.words[fastest.key].text} (${fastest.value.toStringAsFixed(1)}${strings.secondsUnit})',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ],
          if (slowest != null && slowest.key < widget.words.length) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentYellow.withAlpha(70)),
              ),
              child: Text(
                '${strings.slowestWord}: ${widget.words[slowest.key].text} (${slowest.value.toStringAsFixed(1)}${strings.secondsUnit})',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentYellow,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppStrings strings) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ButtonCustomWidget(
            onPressed: () => _navigateTo(const GamePage()),
            text: strings.restart,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  audioPlayer.stop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DictionaryPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.book, size: 18, color: AppColors.textPrimary),
                label: Text(
                  strings.dictionary,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _navigateTo(const HomePage()),
                icon: const Icon(Icons.home, size: 18, color: AppColors.textPrimary),
                label: Text(
                  strings.home,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
