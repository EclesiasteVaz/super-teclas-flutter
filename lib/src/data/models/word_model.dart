class WordModel {
  String text;
  final String difficulty;

  WordModel({
    required this.text,
    this.difficulty = 'medium',
  }) {
    text = text.trim();
  }
}
