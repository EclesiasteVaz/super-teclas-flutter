import 'package:flutter/material.dart';
import 'package:super_teclas/src/ui/pages/game_page.dart';
import 'package:super_teclas/src/ui/widgets/button_costum_widget.dart';
import 'package:super_teclas/src/ui/widgets/title_game_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TitleGameWidget(),
          const SizedBox(height: 15),
          SizedBox(
            width: 180,
            child: ButtonCostumWidget(
              onPressed: () =>
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) => const GamePage(),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
