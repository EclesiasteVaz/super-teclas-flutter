// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';

class PanelTimerWidget extends StatefulWidget {
  PanelTimerWidget(
      {super.key,
      required this.time,
      required this.score,
      required this.level});
  int score;
  int level;
  int time;
  @override
  State<PanelTimerWidget> createState() => _PanelTimerWidgetState();
}

class _PanelTimerWidgetState extends State<PanelTimerWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.level.toString(),
                style: const TextStyle(
                    color: Color.fromARGB(255, 7, 143, 255), fontSize: 20),
              ),
              const Text('Nível'),
            ],
          ),
          Text(
            '0${widget.time}s',
            style: TextStyle(
              fontSize: 30,
              color: (widget.time < 5) ? Colors.red : Colors.green,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.score.toString(),
                style: const TextStyle(
                    color: Color.fromARGB(255, 7, 143, 255), fontSize: 20),
              ),
              const Text('Pontos'),
            ],
          )
        ],
      ),
    );
  }
}
