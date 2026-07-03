import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/i18n/app_strings.dart';

class TitleGameWidget extends StatelessWidget {
  const TitleGameWidget({super.key, this.fontSize = 30});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.from(context);
    final parts = strings.superTeclasTitle.split(' ');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          parts.isNotEmpty ? parts[0] : 'Super',
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.blue[400],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          parts.length > 1 ? parts.sublist(1).join(' ') : 'Teclas',
          style: TextStyle(
            fontSize: fontSize,
            color: const Color.fromARGB(255, 241, 242, 243),
          ),
        ),
      ],
    );
  }
}
