import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';
import 'package:super_teclas/src/ui/pages/home_page.dart';
import 'package:super_teclas/src/ui/widgets/button_costum_widget.dart';

class EndGamePage extends StatefulWidget {
  const EndGamePage({super.key, required this.isWin, required this.level});
  final bool isWin;
  final int level;

  @override
  State<EndGamePage> createState() => _EndGamePageState();
}

class _EndGamePageState extends State<EndGamePage> {
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isWin) {
        await audioPlayer.setSource(AssetSource(
            "audios/brass-fanfare-with-timpani-and-winchimes-reverberated-146260.mp3"));
      } else {
        await audioPlayer.setSource(AssetSource("audios/fail-144746.mp3"));
      }
      await audioPlayer.resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomePage(),
              ),
            ),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 300,
                height: 200,
                child: Image.asset("assets/images/app_icon.png"),
              ),
              if (!widget.isWin)
                Text(
                  "Perdeste",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red[500]!,
                  ),
                )
              else
                Text(
                  "Ganhaste o jogo",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.green[500]!,
                  ),
                ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: const Color.fromARGB(85, 28, 28, 29),
                  child: SizedBox(
                    width: 180,
                    height: 130,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.level.toString(),
                          style: const TextStyle(fontSize: 40),
                        ),
                        const Text("Pontos")
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ButtonCostumWidget(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const GamePage(),
                  ),
                ),
                text: "Recomeçar",
              )
            ],
          ),
        ),
      ),
    );
  }
}
