import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:super_teclas/src/config/env.dart';
import 'package:super_teclas/src/data/models/word_model.dart';

class WordBank {
  static List<WordModel> _words = [];

  static List<WordModel> get words => _words;

  static const _fallbackPt = [
    'Computador',
    'Telefone',
    'Democracia',
    'Programação',
    'Engenharia',
    'Burocracia',
    'Desenvolvimento',
    'Fotossíntese',
    'Paralelepípedo',
    'Responsabilidade',
    'Termodinâmica',
    'Ultravioleta',
    'Ziguezague',
    'Bioquímica',
    'Eletroencefalograma',
    'Idiossincrasia',
  ];

  static const _fallbackEn = [
    'Computer',
    'Telephone',
    'Democracy',
    'Programming',
    'Engineering',
    'Bureaucracy',
    'Development',
    'Photosynthesis',
    'Entrepreneurship',
    'Responsibility',
    'Thermodynamics',
    'Ultraviolet',
    'Zigzag',
    'Biochemistry',
    'Electroencephalogram',
    'Idiosyncrasy',
  ];

  static bool get _isFirestoreAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> load({required String languageCode}) async {
    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';

    if (_isFirestoreAvailable) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('words')
            .where('language', isEqualTo: normalizedLang)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _words = snapshot.docs
              .map(
                (doc) => WordModel.fromMap(
                  doc.data(),
                  defaultLanguage: normalizedLang,
                  docId: doc.id,
                ),
              )
              .where((w) => w.text.isNotEmpty)
              .toList();
          if (_words.isNotEmpty) return;
        }
      } catch (_) {}
    }

    final fileName = normalizedLang == 'pt' ? 'pt.json' : 'en.json';
    try {
      final jsonString = await rootBundle.loadString('assets/words/$fileName');
      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      _words = data.map((item) {
        final map = item as Map<String, dynamic>;
        return WordModel.fromMap(map, defaultLanguage: normalizedLang);
      }).toList();
    } catch (_) {
      final fallback = normalizedLang == 'pt' ? _fallbackPt : _fallbackEn;
      _words = fallback
          .map((text) => WordModel(text: text, language: normalizedLang))
          .toList();
    }
  }

  static List<WordModel> getWords(String languageCode) {
    if (_words.isNotEmpty) return _words;
    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';
    final fallback = normalizedLang == 'pt' ? _fallbackPt : _fallbackEn;
    return fallback
        .map((text) => WordModel(text: text, language: normalizedLang))
        .toList();
  }

  static Future<bool> registerWordsViaEndpoint({
    required String languageCode,
    required String adminToken,
    List<WordModel>? customWords,
    String? apiBaseUrl,
  }) async {
    final baseUrl = (apiBaseUrl ?? Env.apiBaseUrl).trim();
    if (baseUrl.isEmpty || adminToken.trim().isEmpty) return false;

    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';
    final wordsToRegister = customWords ?? getWords(normalizedLang);
    if (wordsToRegister.isEmpty) return false;

    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/register-words',
    );

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${adminToken.trim()}',
        },
        body: jsonEncode({
          'language': normalizedLang,
          'words': wordsToRegister.map((w) => w.toMap()).toList(),
        }),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
