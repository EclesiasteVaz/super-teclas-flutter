import 'package:flutter/material.dart';

class PanelWordWidget extends StatelessWidget {
  const PanelWordWidget({super.key, required this.word});
  final String word;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      alignment: Alignment.center,
      child: Text(
        word,
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
    );
  }
}
