import 'package:flutter/foundation.dart';
import 'package:super_teclas/models/game_model.dart';
import 'package:super_teclas/services/game_timer.dart';
import 'package:super_teclas/services/game_word_manager.dart';

class GamePageEnvetsManager extends ChangeNotifier {
  GameTimer gameTimer = GameTimer();
  GameWordManager gameWordManager = GameWordManager();
  GameModel gameModel = GameModel();
  bool isChampion = false; //indicando se perdeu ou ganhou
  int level = 0;

  GamePageEnvetsManager() {
    gameWordManager.setWords(gameModel.levels[level].words);
  }

  void startLevel() {
    gameTimer.startTimer(gameModel.levels[level].time.toInt());
  }

  void writtingWord({required String wordText}) {
    //vendo se a palavra está errada e o tempo terminou
    if (gameWordManager.checkWord(wordText) == false &&
        gameTimer.timeRemaining <= 0) {
      isChampion = false;
    }
    //vendo se a palvra está certa
    if (gameWordManager.checkWord(wordText) == true &&
        gameWordManager.index == 4) {
      level++;
      gameWordManager.setWords(gameModel.levels[level].words);
    }

    if (gameWordManager.checkWord(wordText) == true &&
        gameWordManager.index < 4) {
      isChampion = true;
    }
  }

  void pauseOrPlayGame(bool isPause) {
    //pausando
    if (isPause) {
      gameTimer.pauseTimer();
    }
    //voltando a jogar
    if (isPause) {
      gameTimer.resumeTimer();
    }
  }
}
