class ScoreModel {
  final int
      scores; // Pontuação para cada nível (chave: nível, valor: pontuação)
  final int _totalScore = 0; // Pontuação total do jogo

  get totalScore => _totalScore;
  ScoreModel({
    required this.scores,
  });
}
