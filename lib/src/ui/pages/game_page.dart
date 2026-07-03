import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:super_teclas/src/services/game_service.dart';
import 'package:super_teclas/src/ui/pages/end_game_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPaused = false;
  bool _isNavigating = false;
  late Timer _timer;
  GameService gameService = GameService();
  final controllerInput = TextEditingController();
  late int lastIndex;
  late int time;
  StreamSubscription? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lastIndex = gameService.currentIndex;
    time = gameService.currentWord.text.length;
    audioPlayer.setReleaseMode(ReleaseMode.release);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await audioPlayer.setVolume(0.3);
      await audioPlayer
          .setSource(AssetSource("audios/stranger-things-124008.mp3"));
      await audioPlayer.resume();
      _playerCompleteSubscription =
          audioPlayer.onPlayerComplete.listen((event) async {
        await audioPlayer
            .setSource(AssetSource("audios/stranger-things-124008.mp3"));
        await audioPlayer.resume();
      });
    });
    gameService.addListener(_onGameEvent);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_isNavigating) return;
        if (!isPaused) {
          time--;
        }
        if (time == 0) {
          _isNavigating = true;
          _timer.cancel();
          audioPlayer.stop();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => EndGamePage(
              isWin: false,
              level: impressLevel(),
            ),
          ));
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
      audioPlayer.stop();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => EndGamePage(
          isWin: true,
          level: impressLevel(),
        ),
      ));
      return;
    }

    if (gameService.currentIndex != lastIndex) {
      controllerInput.text = '';
      time = gameService.currentWord.text.length;
    }
    lastIndex = gameService.currentIndex;
    setState(() {});
  }

  @override
  void dispose() {
    gameService.removeListener(_onGameEvent);
    gameService.dispose();
    _timer.cancel();
    _playerCompleteSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    audioPlayer.dispose();
    controllerInput.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      isPaused = true;
      audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed && !isPaused) {
      audioPlayer.resume();
    }
    setState(() {});
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              isPaused = !isPaused;
              if (isPaused == true) {
                audioPlayer.pause();
              } else {
                audioPlayer.resume();
              }
              setState(() {});
            },
            icon: Icon(!isPaused ? Icons.pause : Icons.play_arrow),
          )
        ],
      ),
      extendBody: true,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          alignment: Alignment.center,
          child: ListView(
            children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            impressLevel().toString(),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const Text("Pontos"),
                        ],
                      ),
                      Container(
                        width: 100,
                        height: 80,
                        alignment: Alignment.center,
                        child: Text(
                          '${time ~/ 60} : ${time % 60}',
                          style: TextStyle(
                            fontSize: 35,
                            color: (time > 5)
                                ? Colors.green
                                : (time > 3)
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 80,
                        alignment: Alignment.center,
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    gameService.currentWord.text,
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      enableSuggestions: false,
                      autofocus: true,
                      autocorrect: false,
                      enabled: !isPaused,
                      controller: controllerInput,
                      onChanged: (text) {
                        gameService.writing(word: text);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Color.fromARGB(111, 37, 37, 37),
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int impressLevel() {
    return switch (gameService.indexWordUseds.length) {
      0 => 0,
      1 => 0,
      final int n when n == gameService.words.length - 1 => 100,
      final int n => ((n / gameService.words.length) * 100).toInt(),
    };
  }
}
