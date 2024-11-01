import 'package:flutter/material.dart';
import 'package:super_teclas/pages/game_page.dart';
import 'package:super_teclas/pages/home_page.dart';
import 'package:super_teclas/shared/components/card_infor_widget.dart';
import 'package:super_teclas/shared/components/list_costum_widget.dart';

class LoserPage extends StatelessWidget {
  const LoserPage({super.key, required this.level, required this.score});
  final int level;
  final int score;
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
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              ),
              icon: const Icon(
                Icons.house_rounded,
                size: 30,
              ),
            )
          ],
        ),
        body: ListCustomWidget(
          child: ListView(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 300,
                      child: Image.asset(
                        'src/images/app_icon.png',
                      ),
                    ),
                    const Text(
                      'Acabou o tempo',
                      style: TextStyle(fontSize: 24),
                    ),
                    const Text(
                      'Você perdeu !!!',
                      style: TextStyle(fontSize: 30, color: Colors.red),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CardInforWidget(
                          value: level,
                          category: 'Ní+vel',
                        ),
                        CardInforWidget(value: score, category: 'Pontuação')
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    ElevatedButton.icon(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        ),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GamePage(),
                          )),
                      icon: const Icon(Icons.restart_alt_outlined),
                      label: const Text('Recomeçar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
