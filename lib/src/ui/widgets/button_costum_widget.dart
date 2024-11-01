import 'package:flutter/material.dart';

class ButtonCostumWidget extends StatelessWidget {
  const ButtonCostumWidget({super.key, required this.onPressed, this.text});
  final Function()? onPressed;
  final String? text;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: const ButtonStyle(
        backgroundColor:
            WidgetStatePropertyAll(Color.fromARGB(255, 5, 74, 129)),
      ),
      onPressed: onPressed,
      child: Text(text ?? "Começar o jogo"),
    );
  }
}
