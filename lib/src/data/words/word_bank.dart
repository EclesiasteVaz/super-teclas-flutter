import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:super_teclas/src/data/models/word_model.dart';

class WordBank {
  static List<WordModel> _words = [];

  static List<WordModel> get words => _words;

  static const _fallbackPt = [
    'Computador', 'Telefone', 'Democracia', 'Programação', 'Engenharia',
    'Burocracia', 'Desenvolvimento', 'Fotossíntese', 'Paralelepípedo',
    'Responsabilidade', 'Termodinâmica', 'Ultravioleta', 'Ziguezague',
    'Bioquímica', 'Eletroencefalograma', 'Idiossincrasia',
  ];

  static const _fallbackEn = [
    'Computer', 'Telephone', 'Democracy', 'Programming', 'Engineering',
    'Bureaucracy', 'Development', 'Photosynthesis', 'Entrepreneurship',
    'Responsibility', 'Thermodynamics', 'Ultraviolet', 'Zigzag',
    'Biochemistry', 'Electroencephalogram', 'Idiosyncrasy',
  ];

  static Future<void> load({required String languageCode}) async {
    final fileName = languageCode == 'pt' ? 'pt.json' : 'en.json';
    try {
      final jsonString = await rootBundle.loadString('assets/words/$fileName');
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      _words = data.map((item) {
        final map = item as Map<String, dynamic>;
        return WordModel(
          text: map['word'] as String,
          difficulty: map['difficulty'] as String? ?? 'medium',
        );
      }).toList();
    } catch (_) {
      final fallback = languageCode == 'pt' ? _fallbackPt : _fallbackEn;
      _words = fallback
          .map((text) => WordModel(text: text))
          .toList();
    }
  }

  static List<WordModel> getWords(String languageCode) {
    if (_words.isNotEmpty) return _words;
    final fallback = languageCode == 'pt' ? _fallbackPt : _fallbackEn;
    return fallback
        .map((text) => WordModel(text: text))
        .toList();
  }
}
