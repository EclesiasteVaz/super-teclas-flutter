import 'package:flutter/material.dart';

class CardInforWidget extends StatelessWidget {
  const CardInforWidget(
      {super.key, required this.value, required this.category});

  final int value;
  final String category;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 130,
      decoration: BoxDecoration(
        color: const Color.fromARGB(22, 74, 78, 82),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 50, color: Colors.blue),
          ),
          Text(
            category,
            style: const TextStyle(
              fontSize: 19,
            ),
          )
        ],
      ),
    );
  }
}
