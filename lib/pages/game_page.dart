import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_teclas/pages/loser_page.dart';
import 'package:super_teclas/services/game_page_envets_manager.dart';
import 'package:super_teclas/shared/components/list_costum_widget.dart';
import 'package:super_teclas/shared/components/panel_timer_widget.dart';
import 'package:super_teclas/shared/components/panel_word_widget.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isGaming = true;
  GamePageEnvetsManager gamePageEnvetsManager = GamePageEnvetsManager();
  bool isTime = true;
  late String currentWord;
  late Timer timerGame;
  int secounds = 0;
  int score = 0;
  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    playNow();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Super',
              style: TextStyle(color: Color.fromARGB(255, 7, 143, 255)),
            ),
            Text(
              'Teclas',
              style: TextStyle(
                decorationStyle: TextDecorationStyle.dashed,
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: pauseGame,
            icon: Icon(
              !isGaming ? Icons.play_arrow_sharp : Icons.pause,
              size: 30,
            ),
          )
        ],
      ),
      extendBody: true,
      body: ListCustomWidget(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: double.infinity,
            alignment: Alignment.center,
            child: ListView(
              children: [
                Column(
                  children: [
                    PanelTimerWidget(
                      time: secounds,
                      score: score,
                      level: gamePageEnvetsManager
                          .gameWordManager.currentWord.level,
                    ),
                    PanelWordWidget(
                      word: gamePageEnvetsManager
                          .gameWordManager.currentWord.text,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CupertinoTextField(
                        controller: textEditingController,
                        enabled: isTime,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(28, 88, 115, 146),
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        placeholder: 'Escreva a palavra aqui...',
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        keyboardAppearance: Brightness.dark,
                        onChanged: writting,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //função para começãr o jogo
  playNow() async {
    await Future.delayed(const Duration(seconds: 1));
    gamePageEnvetsManager.startLevel();
    secounds = gamePageEnvetsManager
        .gameModel.levels[gamePageEnvetsManager.level].time
        .toInt();
    timerGame = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        isTime = thereIsTime();
        if (gamePageEnvetsManager.isChampion == false && secounds > 0) {
          if (isGaming) {
            secounds--;
          }
        }
      });
    });
  }

  //emtendo pausa no jogo
  pauseGame() {
    isGaming = !isGaming;
  }

  //escrevendo a plavavra
  writting(String? word) {
    //conseguiu escrever toda palavra certinha
    if (gamePageEnvetsManager.gameWordManager.checkWord(word!)) {
      timerGame.cancel();
      textEditingController.text = '';
      //novo timer
      timerGame = newTimer();
      if (gamePageEnvetsManager.gameWordManager.index >= 4) {
        gamePageEnvetsManager.gameModel.score += gamePageEnvetsManager
            .gameModel.levels[gamePageEnvetsManager.level].score.scores;
        gamePageEnvetsManager.level++;
        gamePageEnvetsManager.gameWordManager.setWords(gamePageEnvetsManager
            .gameModel.levels[gamePageEnvetsManager.level].words);
        gamePageEnvetsManager.gameWordManager.checkWinnerLevel();
      }
    }
    gamePageEnvetsManager.writtingWord(wordText: word);
  }

  Timer newTimer() {
    timerGame.cancel();
    secounds = gamePageEnvetsManager
        .gameModel.levels[gamePageEnvetsManager.level].time
        .toInt();
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        secounds = (secounds > 0) ? secounds - 1 : secounds;
        if (secounds == 0) {
          timerGame.cancel();
          if (gamePageEnvetsManager.isChampion == false) {
            // print('false champion');
          } else {
            // print('new champion');
          }
        }
        isTime = thereIsTime();
      });
    });
  }

  //validando se o tempo acabou
  bool thereIsTime() {
    if (secounds > 0) {
      return true;
    }
    timerGame.cancel();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoserPage(
              level: gamePageEnvetsManager.gameWordManager.currentWord.level,
              score: gamePageEnvetsManager.gameModel.score),
        ));
    return false;
  }
}
