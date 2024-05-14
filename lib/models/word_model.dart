class WordModel {
  final String text; // A palavra a ser digitada
  final int level; // Nível da palavra
  int timeLimit; // Tempo limite para digitar a palavra (em segundos)

  WordModel({required this.text, required this.level, this.timeLimit = 30});
}
