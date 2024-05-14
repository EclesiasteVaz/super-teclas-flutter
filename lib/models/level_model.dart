import 'package:super_teclas/models/score_model.dart';
import 'package:super_teclas/models/word_model.dart';

class LevelModel {
  int number;
  double time;
  List<WordModel> words;
  ScoreModel score;

  LevelModel(
      {required this.number,
      required this.time,
      required this.words,
      required this.score});
}
