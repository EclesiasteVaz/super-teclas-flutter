import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'package:super_teclas/src/config/env.dart';
import 'package:super_teclas/src/data/models/word_model.dart';

class WordBank {
  static final Map<String, List<WordModel>> _wordsByLanguage = {};
  static final Set<String> _loadedFromFirestore = {};
  static String _activeLanguage = 'pt';

  static List<WordModel> get words =>
      _wordsByLanguage[_activeLanguage] ?? _buildCatalogForLanguage(_activeLanguage);

  static const _catalogPt = <Map<String, String>>[
    {
      'text': 'Casa',
      'difficulty': 'easy',
      'definition': 'Edifício onde moram pessoas',
    },
    {
      'text': 'Foco',
      'difficulty': 'easy',
      'definition': 'Concentração da atenção em uma atividade',
    },
    {
      'text': 'Livro',
      'difficulty': 'easy',
      'definition': 'Conjunto de folhas impressas ou manuscritas encadernadas',
    },
    {
      'text': 'Tempo',
      'difficulty': 'easy',
      'definition': 'Duração contínua na qual os eventos se sucedem',
    },
    {
      'text': 'Telefone',
      'difficulty': 'easy',
      'definition': 'Aparelho de telecomunicação para transmissão de voz',
    },
    {
      'text': 'Janela',
      'difficulty': 'easy',
      'definition': 'Abertura na parede para entrada de luz e ventilação',
    },
    {
      'text': 'Teclado',
      'difficulty': 'easy',
      'definition': 'Periférico composto por teclas para digitação',
    },
    {
      'text': 'Estrela',
      'difficulty': 'easy',
      'definition': 'Astro luminoso que brilha no céu noturno',
    },
    {
      'text': 'Computador',
      'difficulty': 'medium',
      'definition': 'Máquina eletrônica de processamento de dados',
    },
    {
      'text': 'Democracia',
      'difficulty': 'medium',
      'definition': 'Regime político baseado na soberania popular',
    },
    {
      'text': 'Programação',
      'difficulty': 'medium',
      'definition': 'Processo de escrita e manutenção de código para sistemas',
    },
    {
      'text': 'Engenharia',
      'difficulty': 'medium',
      'definition': 'Aplicação de conhecimentos científicos e técnicos',
    },
    {
      'text': 'Burocracia',
      'difficulty': 'medium',
      'definition': 'Sistema administrativo baseado em normas e procedimentos',
    },
    {
      'text': 'Fotossíntese',
      'difficulty': 'medium',
      'definition': 'Processo pelo qual plantas convertem luz em energia',
    },
    {
      'text': 'Ziguezague',
      'difficulty': 'medium',
      'definition': 'Série de linhas ou caminhos que formam ângulos alternados',
    },
    {
      'text': 'Bioquímica',
      'difficulty': 'medium',
      'definition': 'Ciência que estuda os processos químicos nos organismos vivos',
    },
    {
      'text': 'Algoritmo',
      'difficulty': 'medium',
      'definition': 'Sequência finita de instruções para resolver um problema',
    },
    {
      'text': 'Arquitetura',
      'difficulty': 'medium',
      'definition': 'Arte e técnica de projetar espaços e sistemas',
    },
    {
      'text': 'Desenvolvimento',
      'difficulty': 'hard',
      'definition': 'Processo de crescer, evoluir ou progredir continuamente',
    },
    {
      'text': 'Paralelepípedo',
      'difficulty': 'hard',
      'definition': 'Bloco retangular de pedra usado em pavimentação',
    },
    {
      'text': 'Responsabilidade',
      'difficulty': 'hard',
      'definition': 'Obrigação de responder pelas próprias ações e decisões',
    },
    {
      'text': 'Termodinâmica',
      'difficulty': 'hard',
      'definition': 'Ramo da física que estuda o calor e o trabalho',
    },
    {
      'text': 'Ultravioleta',
      'difficulty': 'hard',
      'definition': 'Radiação eletromagnética com comprimento de onda curto',
    },
    {
      'text': 'Eletroencefalograma',
      'difficulty': 'hard',
      'definition': 'Exame que registra a atividade elétrica do cérebro',
    },
    {
      'text': 'Idiossincrasia',
      'difficulty': 'hard',
      'definition': 'Característica comportamental peculiar de um indivíduo',
    },
    {
      'text': 'Inconstitucional',
      'difficulty': 'hard',
      'definition': 'Que contraria os princípios da constituição de um país',
    },
  ];

  static const _catalogEn = <Map<String, String>>[
    {
      'text': 'House',
      'difficulty': 'easy',
      'definition': 'A building where people live',
    },
    {
      'text': 'Focus',
      'difficulty': 'easy',
      'definition': 'The center of interest or activity',
    },
    {
      'text': 'Apple',
      'difficulty': 'easy',
      'definition': 'A round fruit with red or green skin',
    },
    {
      'text': 'Forest',
      'difficulty': 'easy',
      'definition': 'A large area covered chiefly with trees',
    },
    {
      'text': 'Castle',
      'difficulty': 'easy',
      'definition': 'A large fortified building from the Middle Ages',
    },
    {
      'text': 'Garden',
      'difficulty': 'easy',
      'definition': 'A piece of ground used for growing flowers or plants',
    },
    {
      'text': 'Island',
      'difficulty': 'easy',
      'definition': 'A piece of land completely surrounded by water',
    },
    {
      'text': 'Zigzag',
      'difficulty': 'easy',
      'definition': 'A line or course having sharp alternate turns',
    },
    {
      'text': 'Computer',
      'difficulty': 'medium',
      'definition': 'Electronic machine for storing and processing data',
    },
    {
      'text': 'Telephone',
      'difficulty': 'medium',
      'definition': 'System for transmitting voices over a distance',
    },
    {
      'text': 'Democracy',
      'difficulty': 'medium',
      'definition': 'System of government by the whole population',
    },
    {
      'text': 'Programming',
      'difficulty': 'medium',
      'definition': 'The process of writing computer programs',
    },
    {
      'text': 'Engineering',
      'difficulty': 'medium',
      'definition': 'Branch of science and technology concerned with design',
    },
    {
      'text': 'Bureaucracy',
      'difficulty': 'medium',
      'definition': 'System of government with administrative procedures',
    },
    {
      'text': 'Development',
      'difficulty': 'medium',
      'definition': 'The process of developing or being developed',
    },
    {
      'text': 'Biochemistry',
      'difficulty': 'medium',
      'definition': 'Branch of science exploring chemical processes in organisms',
    },
    {
      'text': 'Algorithm',
      'difficulty': 'medium',
      'definition': 'A process or set of rules to be followed in calculations',
    },
    {
      'text': 'Architecture',
      'difficulty': 'medium',
      'definition': 'The art or practice of designing and constructing buildings',
    },
    {
      'text': 'Photosynthesis',
      'difficulty': 'hard',
      'definition': 'Process by which green plants synthesize nutrients from light',
    },
    {
      'text': 'Entrepreneurship',
      'difficulty': 'hard',
      'definition': 'The activity of setting up a business taking financial risks',
    },
    {
      'text': 'Responsibility',
      'difficulty': 'hard',
      'definition': 'The state or fact of having a duty to deal with something',
    },
    {
      'text': 'Thermodynamics',
      'difficulty': 'hard',
      'definition': 'Branch of physical science dealing with heat and energy',
    },
    {
      'text': 'Ultraviolet',
      'difficulty': 'hard',
      'definition': 'Electromagnetic radiation with wavelength shorter than light',
    },
    {
      'text': 'Electroencephalogram',
      'difficulty': 'hard',
      'definition': 'A test that records the electrical activity of the brain',
    },
    {
      'text': 'Idiosyncrasy',
      'difficulty': 'hard',
      'definition': 'A mode of behavior or way of thought peculiar to an individual',
    },
  ];

  static bool get _isFirestoreAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static List<WordModel> _buildCatalogForLanguage(String languageCode) {
    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';
    final rawList = normalizedLang == 'pt' ? _catalogPt : _catalogEn;
    return rawList
        .map(
          (item) => WordModel(
            text: item['text']!,
            difficulty: item['difficulty'] ?? 'medium',
            definition: item['definition'] ?? '',
            language: normalizedLang,
          ),
        )
        .toList();
  }

  static Future<List<WordModel>> _seedFirestoreWords(
    FirebaseFirestore db,
    String normalizedLang,
  ) async {
    final seedModels = _buildCatalogForLanguage(normalizedLang);
    try {
      final batch = db.batch();
      for (final word in seedModels) {
        final docRef = db.collection('words').doc(word.id);
        batch.set(
          docRef,
          {
            ...word.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (_) {}
    return seedModels;
  }

  static Future<void> load({
    required String languageCode,
    bool forceRefresh = false,
  }) async {
    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';
    _activeLanguage = normalizedLang;

    if (!forceRefresh &&
        _loadedFromFirestore.contains(normalizedLang) &&
        (_wordsByLanguage[normalizedLang]?.isNotEmpty ?? false)) {
      return;
    }

    if (_isFirestoreAvailable) {
      try {
        final db = FirebaseFirestore.instance;
        final snapshot = await db
            .collection('words')
            .where('language', isEqualTo: normalizedLang)
            .get();

        if (snapshot.docs.isEmpty) {
          final seeded = await _seedFirestoreWords(db, normalizedLang);
          _wordsByLanguage[normalizedLang] = seeded;
          _loadedFromFirestore.add(normalizedLang);
          return;
        }

        final loaded = snapshot.docs
            .map(
              (doc) => WordModel.fromMap(
                doc.data(),
                defaultLanguage: normalizedLang,
                docId: doc.id,
              ),
            )
            .where((w) => w.text.isNotEmpty)
            .toList();
        if (loaded.isNotEmpty) {
          _wordsByLanguage[normalizedLang] = loaded;
          _loadedFromFirestore.add(normalizedLang);
          return;
        }
      } catch (_) {}
    }

    _wordsByLanguage[normalizedLang] = _buildCatalogForLanguage(normalizedLang);
  }

  static List<WordModel> getWords(String languageCode) {
    final normalizedLang = languageCode == 'en' ? 'en' : 'pt';
    final cached = _wordsByLanguage[normalizedLang];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    return _buildCatalogForLanguage(normalizedLang);
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
