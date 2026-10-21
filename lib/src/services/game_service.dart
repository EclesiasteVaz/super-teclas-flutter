import 'dart:math';

import 'package:flutter/material.dart';

import 'package:super_teclas/src/data/models/game_session_model.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';

class GameService extends ChangeNotifier {
  static const int maxPauses = 3;

  List<WordModel> words = [];
  final Random random = Random();
  final List<int> indexWordUseds = [];
  late WordModel currentWord;
  bool isWin = false;
  GameStatus status = GameStatus.running;
  int pauseCount = 0;
  int totalPausedDurationMs = 0;
  DateTime? _pauseStartedAt;
  int _currentWordPausedMs = 0;
  int currentIndex = 0;
  int totalKeystrokes = 0;
  int correctKeystrokes = 0;
  int totalWordsCompleted = 0;
  int totalPoints = 0;
  int lastWordPoints = 0;
  DateTime? startTime;
  DateTime? finishedAt;
  DateTime? _currentWordStartTime;
  final Map<int, double> _wordTimes = {};
  final List<GameWordLog> _wordsLog = [];
  String languageCode;
  String? gameId;
  bool isServerAuthoritative = false;
  bool isSubmittingWord = false;
  int wordSequence = 1;
  int totalWordsPool = 0;
  DateTime? wordDeadlineAt;
  int? _serverRemainingTimeMs;

  GameService({this.languageCode = 'pt'}) {
    _init(languageCode);
  }

  bool get isRunning => status == GameStatus.running;

  bool get isPaused => status == GameStatus.paused;

  bool get isFinished => status == GameStatus.finished;

  bool get canPause => status == GameStatus.running && pauseCount < maxPauses;

  int get remainingPauses => (maxPauses - pauseCount).clamp(0, maxPauses);

  int get sessionTotalWords => totalWordsPool > 0
      ? totalWordsPool
      : (words.isNotEmpty ? words.length : 200);

  List<GameWordLog> get wordsLog => List.unmodifiable(_wordsLog);

  void _init(String languageCode) {
    words = WordBank.getWords(languageCode)
        .map(
          (model) => WordModel(
            id: model.id,
            text: model.text,
            difficulty: model.difficulty,
            definition: model.definition,
            language: model.language,
            expectedDurationMs: model.expectedDurationMs,
          ),
        )
        .toList();
    if (words.isNotEmpty) {
      this.languageCode = words.first.language;
    }
    totalWordsPool = words.length;
    currentIndex = random.nextInt(words.length);
    indexWordUseds
      ..clear()
      ..add(currentIndex);
    currentWord = words[currentIndex];
    status = GameStatus.running;
    final now = DateTime.now();
    startTime = now;
    _currentWordStartTime = now;
    notifyListeners();
  }

  void setLanguage(String newLanguageCode) {
    final normalized = newLanguageCode == 'en' ? 'en' : 'pt';
    if (languageCode == normalized && words.isNotEmpty) return;
    languageCode = normalized;
    if (!isServerAuthoritative && totalWordsCompleted == 0) {
      _init(normalized);
    }
  }

  DateTime _computeClientDeadline(ServerGameStepResult result, DateTime now) {
    if (result.wordDeadlineAtMs != null && result.serverNowMs != null) {
      final deltaMs =
          (result.wordDeadlineAtMs! - result.serverNowMs!).clamp(0, 60000);
      return now.add(Duration(milliseconds: deltaMs));
    }
    if (result.wordDeadlineAtMs != null) {
      return DateTime.fromMillisecondsSinceEpoch(result.wordDeadlineAtMs!);
    }
    return now.add(Duration(milliseconds: result.remainingTimeMs));
  }

  void applyServerStart(ServerGameStepResult result) {
    isServerAuthoritative = true;
    isSubmittingWord = false;
    gameId = result.gameId;
    status = result.status;
    isWin = result.isWin;
    wordSequence = result.wordSequence;
    totalWordsPool = result.totalWordsPool;
    pauseCount = result.pauseCount;
    totalPausedDurationMs = 0;
    _pauseStartedAt = null;
    totalKeystrokes = 0;
    correctKeystrokes = 0;
    totalPoints = result.score;
    lastWordPoints = result.lastWordPoints;
    totalWordsCompleted = result.wordsCompleted;
    _serverRemainingTimeMs = result.remainingTimeMs;
    _wordTimes.clear();
    _wordsLog.clear();

    final now = DateTime.now();
    startTime = now;
    finishedAt = null;
    _currentWordStartTime = now;
    _currentWordPausedMs = 0;
    wordDeadlineAt = _computeClientDeadline(result, now);

    if (result.currentWord != null) {
      final serverWord = result.currentWord!;
      words = [serverWord];
      currentWord = serverWord;
      currentIndex = 0;
      indexWordUseds
        ..clear()
        ..add(0);
    }

    notifyListeners();
  }

  void applyServerStep(ServerGameStepResult result) {
    isSubmittingWord = false;
    pauseCount = result.pauseCount;
    if (result.wordSequence > 0) {
      wordSequence = result.wordSequence;
    }
    if (result.totalWordsPool > 0) {
      totalWordsPool = result.totalWordsPool;
    }

    final now = DateTime.now();

    if (result.wordsCompleted > totalWordsCompleted) {
      final completedWord = currentWord;
      final wordStart = _currentWordStartTime ?? now;
      final elapsedMs = result.actualDurationMs > 0
          ? result.actualDurationMs
          : (now.difference(wordStart).inMilliseconds - _currentWordPausedMs)
              .clamp(1, 600000);
      _wordTimes[currentIndex] = elapsedMs / 1000.0;
      final awarded = result.lastWordPoints > 0
          ? result.lastWordPoints
          : WordModel.calculateWordPoints(
              difficulty: completedWord.difficulty,
              expectedDurationMs: completedWord.expectedDurationMs,
              actualDurationMs: elapsedMs,
            );
      _wordsLog.add(
        GameWordLog(
          wordId: completedWord.id,
          wordText: completedWord.text,
          difficulty: completedWord.difficulty,
          length: completedWord.length,
          expectedDurationMs: completedWord.expectedDurationMs,
          actualDurationMs: elapsedMs,
          startedAt: wordStart,
          completedAt: now,
          stateWhenTyped: GameStatus.running.name,
          pointsAwarded: awarded,
        ),
      );
      lastWordPoints = awarded;
      _currentWordPausedMs = 0;
    } else if (result.lastWordPoints > 0) {
      lastWordPoints = result.lastWordPoints;
    }

    totalPoints = result.score;
    totalWordsCompleted = result.wordsCompleted;

    if (result.status == GameStatus.finished) {
      wordDeadlineAt = null;
      _serverRemainingTimeMs = 0;
      finishGame(win: result.isWin);
      return;
    }

    if (result.status == GameStatus.paused) {
      status = GameStatus.paused;
      _pauseStartedAt ??= now;
      _serverRemainingTimeMs = result.remainingTimeMs;
      wordDeadlineAt = null;
      notifyListeners();
      return;
    }

    if (_pauseStartedAt != null) {
      final pausedMs = now.difference(_pauseStartedAt!).inMilliseconds;
      if (pausedMs > 0) {
        totalPausedDurationMs += pausedMs;
        _currentWordPausedMs += pausedMs;
      }
      _pauseStartedAt = null;
    }

    status = GameStatus.running;
    _serverRemainingTimeMs = result.remainingTimeMs;
    wordDeadlineAt = _computeClientDeadline(result, now);

    if (result.currentWord != null &&
        result.currentWord!.text != currentWord.text) {
      final nextWord = result.currentWord!;
      words.add(nextWord);
      currentWord = nextWord;
      currentIndex = words.length - 1;
      indexWordUseds.add(currentIndex);
      _currentWordStartTime = now;
      _currentWordPausedMs = 0;
    }

    notifyListeners();
  }

  bool pauseGame() {
    if (isWin || status != GameStatus.running) return false;
    if (pauseCount >= maxPauses) return false;

    pauseCount++;
    status = GameStatus.paused;
    _pauseStartedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  bool resumeGame() {
    if (isWin || status != GameStatus.paused) return false;

    if (_pauseStartedAt != null) {
      final pausedMs =
          DateTime.now().difference(_pauseStartedAt!).inMilliseconds;
      if (pausedMs > 0) {
        totalPausedDurationMs += pausedMs;
        _currentWordPausedMs += pausedMs;
      }
      _pauseStartedAt = null;
    }

    status = GameStatus.running;
    notifyListeners();
    return true;
  }

  void finishGame({bool win = false}) {
    if (status == GameStatus.finished) return;

    if (_pauseStartedAt != null) {
      final pausedMs =
          DateTime.now().difference(_pauseStartedAt!).inMilliseconds;
      if (pausedMs > 0) {
        totalPausedDurationMs += pausedMs;
        _currentWordPausedMs += pausedMs;
      }
      _pauseStartedAt = null;
    }

    if (win) {
      isWin = true;
    }
    status = GameStatus.finished;
    finishedAt = DateTime.now();
    notifyListeners();
  }

  void writing({required String word}) {
    if (isWin || status != GameStatus.running) return;

    if (word.length != words[currentIndex].text.length) return;
    if (word != words[currentIndex].text) return;

    final now = DateTime.now();
    final wordStart = _currentWordStartTime ?? now;
    final rawElapsedMs =
        (now.difference(wordStart).inMilliseconds - _currentWordPausedMs)
            .clamp(0, 600000);
    _wordTimes[currentIndex] = rawElapsedMs / 1000.0;

    final completedWord = words[currentIndex];
    final wordPoints = WordModel.calculateWordPoints(
      difficulty: completedWord.difficulty,
      expectedDurationMs: completedWord.expectedDurationMs,
      actualDurationMs: rawElapsedMs,
    );

    lastWordPoints = wordPoints;
    totalPoints += wordPoints;
    _wordsLog.add(
      GameWordLog(
        wordId: completedWord.id,
        wordText: completedWord.text,
        difficulty: completedWord.difficulty,
        length: completedWord.length,
        expectedDurationMs: completedWord.expectedDurationMs,
        actualDurationMs: rawElapsedMs,
        startedAt: wordStart,
        completedAt: now,
        stateWhenTyped: status.name,
        pointsAwarded: wordPoints,
      ),
    );
    _currentWordPausedMs = 0;

    totalWordsCompleted++;

    if (words.length == (indexWordUseds.length + 1)) {
      isWin = true;
      status = GameStatus.finished;
      finishedAt = now;
      notifyListeners();
      return;
    }

    int newIndex;
    do {
      newIndex = random.nextInt(words.length);
    } while (indexWordUseds.contains(newIndex));

    currentWord = words[newIndex];
    indexWordUseds.add(newIndex);
    currentIndex = newIndex;
    _currentWordStartTime = DateTime.now();
    notifyListeners();
  }

  int getTimeForWord() {
    if (isServerAuthoritative &&
        _serverRemainingTimeMs != null &&
        _serverRemainingTimeMs! > 0) {
      return (_serverRemainingTimeMs! / 1000).ceil().clamp(1, 15);
    }
    return currentWord.text.length.clamp(8, 15);
  }

  int getRemainingSecondsFromDeadline() {
    if (!isServerAuthoritative || wordDeadlineAt == null) {
      return getTimeForWord();
    }
    final remainingMs =
        wordDeadlineAt!.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil().clamp(0, 15);
  }

  double get accuracy {
    if (totalKeystrokes == 0) return 100;
    return ((correctKeystrokes / totalKeystrokes) * 100).clamp(0, 100);
  }

  double get wordsPerMinute {
    if (startTime == null) return 0;
    final elapsedMs = DateTime.now().difference(startTime!).inMilliseconds -
        totalPausedDurationMs;
    final elapsedSeconds = elapsedMs / 1000.0;
    if (elapsedSeconds <= 0) return 0;
    return (totalWordsCompleted / elapsedSeconds) * 60;
  }

  int get progressPercentage {
    final poolSize = sessionTotalWords;
    final raw = switch (indexWordUseds.length) {
      0 => 0,
      1 => 0,
      final int n when n == poolSize - 1 => 100,
      final int n => ((n / poolSize) * 100).toInt(),
    };
    return raw.clamp(0, 100);
  }

  int get score => totalPoints;

  void recordKeystroke() {
    if (isWin || status != GameStatus.running) return;
    totalKeystrokes++;
  }

  void addCorrectKeystroke() {
    if (isWin || status != GameStatus.running) return;
    correctKeystrokes++;
  }

  Map<int, double> get wordTimes => Map.unmodifiable(_wordTimes);

  double get averageTimePerWord {
    if (_wordTimes.isEmpty) return 0;
    final total = _wordTimes.values.reduce((a, b) => a + b);
    return total / _wordTimes.length;
  }

  String get fastestWordText {
    if (_wordTimes.isEmpty) return '';
    final minEntry = _wordTimes.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    return words[minEntry.key].text;
  }

  String get slowestWordText {
    if (_wordTimes.isEmpty) return '';
    final maxEntry = _wordTimes.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return words[maxEntry.key].text;
  }

  double get fastestWordTime {
    if (_wordTimes.isEmpty) return 0;
    return _wordTimes.values.reduce((a, b) => a < b ? a : b);
  }

  double get slowestWordTime {
    if (_wordTimes.isEmpty) return 0;
    return _wordTimes.values.reduce((a, b) => a > b ? a : b);
  }

  GameSessionModel toSessionModel({
    required String userId,
    required String username,
    String? customGameId,
  }) {
    final now = DateTime.now();
    return GameSessionModel(
      gameId: customGameId ??
          gameId ??
          'local_${(startTime ?? now).millisecondsSinceEpoch}',
      userId: userId,
      username: username,
      languageCode: languageCode,
      status: status,
      score: score,
      wordsCompleted: totalWordsCompleted,
      accuracy: accuracy,
      averageSpeed: averageTimePerWord,
      pauseCount: pauseCount,
      totalPausedDurationMs: totalPausedDurationMs,
      startedAt: startTime ?? now,
      finishedAt: finishedAt,
      wordsLog: wordsLog,
    );
  }
}
