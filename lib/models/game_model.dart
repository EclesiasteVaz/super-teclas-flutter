import 'package:super_teclas/models/level_model.dart';
import 'package:super_teclas/models/score_model.dart';
import 'package:super_teclas/models/word_model.dart';

class GameModel {
  List<LevelModel> levels;
  int score = 0;
  GameModel()
      : levels = [
          //nível 1 a ser preenchido
          LevelModel(
            number: 1,
            time: 9,
            words: <WordModel>[
              WordModel(text: 'Computador', level: 1),
              WordModel(text: 'Telefone', level: 1),
              WordModel(text: 'Democracia', level: 1),
              WordModel(text: 'Esmiuçamento', level: 1),
              WordModel(text: 'Incandescente', level: 1),
            ],
            score: ScoreModel(
              scores: 2,
            ),
          ),
          //nível 2 a ser preenchido
          LevelModel(
            number: 2,
            time: 8,
            words: <WordModel>[
              WordModel(text: 'Ministério', level: 2),
              WordModel(text: 'Programação', level: 2),
              WordModel(text: 'Unanimidade', level: 2),
              WordModel(text: 'Geomagnetismo', level: 2),
              WordModel(text: 'Quilialismo', level: 2)
            ],
            score: ScoreModel(scores: 8),
          ),
          //nível 3 a ser preenchido
          LevelModel(
            number: 3,
            time: 7,
            words: <WordModel>[
              WordModel(text: 'Argumentação', level: 3),
              WordModel(text: 'Devastação', level: 3),
              WordModel(text: 'Fobofóbico', level: 3),
              WordModel(text: 'Legibilidade', level: 3),
              WordModel(text: 'Legislativamente', level: 2)
            ],
            score: ScoreModel(scores: 8),
          ),
          //nível 3 a ser preenchido
          LevelModel(
            number: 4,
            time: 6,
            words: <WordModel>[
              WordModel(text: 'Expansionismo', level: 4),
              WordModel(text: 'buckminsterfulereno', level: 4),
              WordModel(text: 'Guadamecileiro', level: 4),
              WordModel(text: 'Pan-africanismo', level: 4),
              WordModel(text: 'Humedecimento', level: 4)
            ],
            score: ScoreModel(scores: 14),
          ),

          //nível 2 a ser preenchido
          LevelModel(
            number: 5,
            time: 5,
            words: <WordModel>[
              WordModel(text: 'Unanimemente', level: 5),
              WordModel(text: 'Dactiloscopia', level: 5),
              WordModel(text: 'Tecnônimo', level: 5),
              WordModel(text: 'Telecomunicação', level: 5),
              WordModel(text: 'Engenharia', level: 5)
            ],
            score: ScoreModel(scores: 14),
          )
        ];
}
