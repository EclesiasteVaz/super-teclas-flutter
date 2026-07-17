class WordModel {
  String text;
  final String difficulty;
  final String definition;

  WordModel({
    required this.text,
    this.difficulty = 'medium',
    this.definition = '',
  }) {
    text = text.trim();
  }
}
