import 'package:flutter/material.dart';
import 'package:super_teclas/pages/game_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outlined))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Super',
                    style: TextStyle(
                        fontSize: 35, color: Color.fromARGB(255, 7, 143, 255)),
                  ),
                  Text(
                    'Teclas',
                    style: TextStyle(
                      fontSize: 35,
                      decorationStyle: TextDecorationStyle.dashed,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () => goToGame(context),
                  child: const Text('Começar o jogo'))
            ],
          ),
        ),
      ),
    );
  }

  // ## NAVEGANDO para jogo
  goToGame(context) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const GamePage(),
        ));
  }
}
