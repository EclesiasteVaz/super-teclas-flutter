import 'dart:math';
import 'package:flutter/material.dart';
import 'package:super_teclas/src/data/models/word_model.dart';

class GameService extends ChangeNotifier {
  List<WordModel> words = [
    WordModel(text: 'Computador'),
    WordModel(text: 'Telefone'),
    WordModel(text: 'Democracia'),
    WordModel(text: 'Esmiuçamento'),
    WordModel(text: 'Incandescente'),
    WordModel(text: 'Ministério'),
    WordModel(text: 'Programação'),
    WordModel(text: 'Unanimidade'),
    WordModel(text: 'Geomagnetismo'),
    WordModel(text: 'Quilialismo'),
    WordModel(text: 'Argumentação'),
    WordModel(text: 'Devastação'),
    WordModel(text: 'Fobofóbico'),
    WordModel(text: 'Legibilidade'),
    WordModel(text: 'Legislativamente'),
    WordModel(text: 'Expansionismo'),
    WordModel(text: 'Guadamecileiro'),
    WordModel(text: 'Pan-africanismo'),
    WordModel(text: 'Humedecimento'),
    WordModel(text: 'Unanimemente'),
    WordModel(text: 'Dactiloscopia'),
    WordModel(text: 'Tecnônimo'),
    WordModel(text: 'Telecomunicação'),
    WordModel(text: 'Engenharia')
  ];
  Random random = Random();
  List<int> indexWordUseds = [];
  late WordModel currentWord;
  bool isWin = false;
  int currentIndex = 0;

  GameService() {
    currentIndex = random.nextInt(words.length);
    indexWordUseds.add(currentIndex);
    currentWord = words[currentIndex];
    notifyListeners();
  }

  writing({required String word}) {
    if (word.length == words[currentIndex].text.length) {
      if (word == words[currentIndex].text) {
        if (words.length == (indexWordUseds.length + 1)) {
          isWin = true;
          notifyListeners();
          return;
        }
        bool newIndexAvalaide = false;
        do {
          int newIndex = random.nextInt(words.length);
          if (!indexWordUseds.contains(newIndex)) {
            currentWord.text = words[newIndex].text;
            indexWordUseds.add(newIndex);
            currentIndex = newIndex;
            notifyListeners();
          }
        } while (newIndexAvalaide == true);
      }
    }
  }
}
