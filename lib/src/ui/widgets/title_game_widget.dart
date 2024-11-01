import 'package:flutter/material.dart';

class TitleGameWidget extends StatelessWidget {
  const TitleGameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Super",
          style: TextStyle(
            fontSize: 30,
            color: Colors.blue[400],
          ),
        ),
        const Text(
          "Teclas",
          style: TextStyle(
            fontSize: 30,
            color: Color.fromARGB(255, 241, 242, 243),
          ),
        ),
      ],
    );
  }
}
