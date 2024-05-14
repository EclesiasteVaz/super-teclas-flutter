import 'package:super_teclas/models/word_model.dart';

class GameWordManager {
  List<WordModel> _words = [];
  int _currentWordIndex = 0;

  void setWords(List<WordModel> words) {
    _words = words;
  }

  WordModel get currentWord => _words[_currentWordIndex];

  bool checkWord(String typedWord) {
    if (typedWord == _words[_currentWordIndex].text) {
      _currentWordIndex++;
      return true; //palavra certa sem
    } else {
      return false; // Erro
    }
  }

  bool checkWinnerLevel() {
    if (_currentWordIndex < _words.length) {
      _currentWordIndex = 0;
      return false; // nível finalizado
    } else {
      return true; // Próxima palavra
    }
  }

  int get index => _currentWordIndex;
}
