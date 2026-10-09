import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  String get langCode => locale.languageCode;
  bool get isPortuguese => langCode == 'pt';

  static AppStrings from(BuildContext context) {
    return AppStrings(Localizations.localeOf(context));
  }

  String get startGame => isPortuguese ? 'Começar o jogo' : 'Start Game';
  String get restart => isPortuguese ? 'Recomeçar' : 'Restart';
  String get home => isPortuguese ? 'Início' : 'Home';
  String get points => isPortuguese ? 'Pontos' : 'Score';
  String get youWin => isPortuguese ? 'Ganhaste o jogo!' : 'You Win!';
  String get youLose => isPortuguese ? 'Perdeste!' : 'You Lost!';
  String get timeUp => isPortuguese ? 'Acabou o tempo!' : 'Time\'s Up!';
  String get typeWord => isPortuguese ? 'Escreve a palavra aqui...' : 'Type the word here...';
  String get pause => isPortuguese ? 'Pausa' : 'Pause';
  String get soundOn => isPortuguese ? 'Som: Ligado' : 'Sound: On';
  String get soundOff => isPortuguese ? 'Som: Desligado' : 'Sound: Off';
  String get instructions => isPortuguese
      ? 'Digita a palavra antes do tempo acabar.\nCada palavra correta dá mais tempo!'
      : 'Type the word before time runs out.\nEach correct word gives you more time!';
  String get progress => isPortuguese ? 'Progresso' : 'Progress';
  String get wordsPerMinute => isPortuguese ? 'Palavras por minuto' : 'Words per minute';
  String get bestScore => isPortuguese ? 'Melhor pontuação' : 'Best score';
  String get newBest => isPortuguese ? 'NOVO RECORDE!' : 'NEW RECORD!';
  String get howToPlay => isPortuguese
      ? 'Como jogar?'
      : 'How to play?';
  String get instructionsFull => isPortuguese
      ? 'Digita corretamente a palavra que aparece no ecrã antes do tempo acabar. Quanto mais rápido digitares, melhor!'
      : 'Type the word shown on screen correctly before time runs out. The faster you type, the better!';
  String get language => isPortuguese ? 'Idioma' : 'Language';
  String get portuguese => 'Português';
  String get english => 'English';
  String get muteMusic => isPortuguese ? 'Música' : 'Music';
  String get muteSFX => isPortuguese ? 'Efeitos sonoros' : 'Sound effects';
  String get scorePoints => isPortuguese ? 'pontos' : 'points';
  String get level => isPortuguese ? 'Nível' : 'Level';
  String get wordsCount => isPortuguese ? 'palavras' : 'words';
  String get ofWord => isPortuguese ? 'de' : 'of';
  String get timeBonus => isPortuguese ? 'Bónus de tempo' : 'Time bonus';
  String get accuracy => isPortuguese ? 'Precisão' : 'Accuracy';
  String get tryAgain => isPortuguese ? 'Tentar novamente' : 'Try again';
  String get shareResult => isPortuguese ? 'Partilhar resultado' : 'Share result';
  String get save => isPortuguese ? 'Salvar' : 'Save';
  String get pressEnter => isPortuguese ? 'Enter para começar' : 'Press Enter to start';
  String get pressEsc => isPortuguese ? 'ESC para pausar' : 'ESC to pause';
  String get pressM => isPortuguese ? 'M para som' : 'M for sound';
  String get usernameTaken => isPortuguese ? 'Nome já está sendo usado' : 'Username already in use';
  String get superTeclasTitle => isPortuguese ? 'Super Teclas' : 'Super Keys';
  String get dictionary => isPortuguese ? 'Dicionário' : 'Dictionary';
  String get searchHint => isPortuguese ? 'Pesquisar palavra...' : 'Search word...';
  String get allWords => isPortuguese ? 'Todas' : 'All';
  String get easy => isPortuguese ? 'Fácil' : 'Easy';
  String get medium => isPortuguese ? 'Médio' : 'Medium';
  String get hard => isPortuguese ? 'Difícil' : 'Hard';
  String get noResults => isPortuguese ? 'Nenhuma palavra encontrada' : 'No words found';
  String get typingSpeed => isPortuguese ? 'Velocidade de digitação' : 'Typing speed';
  String get averageTime => isPortuguese ? 'Tempo médio' : 'Average time';
  String get fastestWord => isPortuguese ? 'Mais rápida' : 'Fastest';
  String get slowestWord => isPortuguese ? 'Mais lenta' : 'Slowest';
  String get secondsUnit => isPortuguese ? 'seg' : 'sec';
  String get rankingEmpty => isPortuguese ? 'Nenhum registro encontrado' : 'No records found';
  String get close => isPortuguese ? 'Fechar' : 'Close';
  String get rankingTitle => isPortuguese ? 'Ranking' : 'Ranking';
  String get practice => isPortuguese ? 'Praticar' : 'Practice';
  String get leaderboard => isPortuguese ? 'Placar' : 'Leaderboard';
  String get settings => isPortuguese ? 'Ajustes' : 'Settings';
  String get play => isPortuguese ? 'Jogar' : 'Play';
  String get saveProfile => isPortuguese ? 'Salvar Perfil' : 'Save Profile';
  String get updatedJustNow => isPortuguese ? 'ATUALIZADO AGORA' : 'UPDATED JUST NOW';
  String get player => isPortuguese ? 'Jogador' : 'Player';
  String get seeFullRanking => isPortuguese ? 'Ver ranking completo' : 'View full ranking';
  String get dailyGoal => isPortuguese ? 'Meta Diária' : 'Daily Goal';
  String get timeTrial => 'Time Trial';
  String get timeTrialSubtitle => isPortuguese ? '60 segundos' : '60 seconds';
  String get suddenDeath => 'Sudden Death';
  String get suddenDeathSubtitle => isPortuguese ? '1 Erro = Fim' : '1 Error = Game Over';
  String get globalActivity => isPortuguese ? 'Atividade Global' : 'Global Activity';
  String get session => isPortuguese ? 'Sessão' : 'Session';
  String get difficultyLabel => isPortuguese ? 'Dificuldade' : 'Difficulty';
  String get bonusLabel => isPortuguese ? 'Bônus' : 'Bonus';
  String get resetKeyHint => isPortuguese ? 'Resetar' : 'Reset';
  String get confirmKeyHint => isPortuguese ? 'Confirmar' : 'Confirm';
  String get footerTagline => isPortuguese
      ? '© 2024 Super Teclas. Alta Performance em Digitação.'
      : '© 2024 Super Teclas. High Performance Typing.';
  String get instructionsLine1 => isPortuguese
      ? 'Digita a palavra antes do tempo acabar.'
      : 'Type the word before time runs out.';
  String get instructionsLine2 => isPortuguese
      ? 'Cada palavra correta dá mais tempo!'
      : 'Each correct word gives you more time!';
}
