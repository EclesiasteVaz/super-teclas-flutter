import 'dart:math';
import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/models/word_model.dart';
import 'package:super_teclas/src/data/words/word_bank.dart';

class GameService extends ChangeNotifier {
  List<WordModel> words = [];
  final Random random = Random();
  final List<int> indexWordUseds = [];
  late WordModel currentWord;
  bool isWin = false;
  int currentIndex = 0;
  int totalKeystrokes = 0;
  int correctKeystrokes = 0;
  int totalWordsCompleted = 0;
  DateTime? startTime;
  DateTime? _currentWordStartTime;
  final Map<int, double> _wordTimes = {};
  String languageCode;

  GameService({this.languageCode = 'pt'}) {
    _init(languageCode);
  }

  void _init(String languageCode) {
    words = WordBank.getWords(languageCode)
        .map((model) => WordModel(text: model.text, difficulty: model.difficulty))
        .toList();
    currentIndex = random.nextInt(words.length);
    indexWordUseds.add(currentIndex);
    currentWord = words[currentIndex];
    startTime = DateTime.now();
    _currentWordStartTime = DateTime.now();
    notifyListeners();
  }

  void writing({required String word}) {
    if (isWin) return;

    if (word.length != words[currentIndex].text.length) return;
    if (word != words[currentIndex].text) return;

    if (_currentWordStartTime != null) {
      final elapsed = DateTime.now().difference(_currentWordStartTime!).inMilliseconds / 1000.0;
      _wordTimes[currentIndex] = elapsed;
    }

    totalWordsCompleted++;
    correctKeystrokes += word.length;

    if (words.length == (indexWordUseds.length + 1)) {
      isWin = true;
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
    return currentWord.text.length.clamp(8, 15);
  }

  double get accuracy {
    if (totalKeystrokes == 0) return 100;
    return (correctKeystrokes / totalKeystrokes) * 100;
  }

  double get wordsPerMinute {
    if (startTime == null) return 0;
    final elapsed = DateTime.now().difference(startTime!).inSeconds;
    if (elapsed == 0) return 0;
    return (totalWordsCompleted / elapsed) * 60;
  }

  int get score {
    return switch (indexWordUseds.length) {
      0 => 0,
      1 => 0,
      final int n when n == words.length - 1 => 100,
      final int n => ((n / words.length) * 100).toInt(),
    };
  }

  void recordKeystroke() {
    totalKeystrokes++;
  }

  void addCorrectKeystroke() {
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
}
