import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';

class ButtonCustomWidget extends StatelessWidget {
  const ButtonCustomWidget({super.key, required this.onPressed, this.text});
  final Function()? onPressed;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    return ElevatedButton(
      style: const ButtonStyle(
        backgroundColor:
            WidgetStatePropertyAll(Color.fromARGB(255, 5, 74, 129)),
      ),
      onPressed: onPressed,
      child: Text(text ?? strings.startGame),
    );
  }
}
