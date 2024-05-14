import 'dart:async';
import 'package:flutter/material.dart';

class GameTimer extends ChangeNotifier {
  final Stopwatch _stopwatch = Stopwatch();
  int _timeRemaining = 0;
  Timer? _timer;

  void startTimer(int timeLimit) {
    _stopwatch.reset();
    _stopwatch.start();
    _timeRemaining = timeLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _stopwatch.stop();
        notifyListeners(); // Chamar o notifyListeners para indicar que o tempo acabou
      }
    });
  }

  void pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void resumeTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _stopwatch.stop();
        notifyListeners();
      }
    });
  }

  int get timeRemaining => _timeRemaining;

  Stream<int> get timeRemainingStream =>
      Stream.periodic(const Duration(seconds: 1), (_) => _timeRemaining);

  // ignore: must_call_super, annotate_overrides
  void dispose() {
    _timer!.cancel();
  }
}
