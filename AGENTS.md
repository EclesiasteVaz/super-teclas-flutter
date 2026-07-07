# AGENTS.md — Super Teclas

## 📋 Identidade do Projeto

- **Nome:** `super_teclas` — Jogo de digitação rápida contra o tempo em Flutter
- **Versão:** `1.0.0+1` | **SDK:** Dart `>=3.5.0 <4.0.0` | **Flutter:** stable (>=3.38.4)
- **Plataformas:** Android, iOS, Linux, Windows, Web
- **Publish:** privado (`publish_to: 'none'`)
- **Repositório:** Git, branch ativa `develop`
- **Deploy:** Vercel (`build/web`)

---

## 🏗️ Arquitetura & Estrutura

### Camadas

```
lib/
├── main.dart                         # Entry point, LocaleProvider, tema
├── utils/
│   ├── game_color_status.dart        # Cores por "nível" (verde/azul/laranja/cinza)
│   └── game_time.dart                # Formatação MM:SS
└── src/
    ├── data/
    │   ├── i18n/app_strings.dart     # 56 strings PT/EN com AppStrings
    │   ├── models/word_model.dart    # WordModel (faz trim no construtor)
    │   └── words/word_bank.dart      # 48 palavras PT + 48 EN
    ├── services/
    │   └── game_service.dart         # ChangeNotifier com lógica do jogo
    └── ui/
        ├── pages/
        │   ├── home_page.dart        # Tela inicial com high score
        │   ├── game_page.dart        # Tela principal do jogo (369 linhas)
        │   └── end_game_page.dart    # Resultado com confete (285 linhas)
        └── widgets/
            ├── button_costum_widget.dart  # Botão azul escuro reutilizável
            └── title_game_widget.dart     # Título "Super" azul + "Teclas" branco
```

### Padrão Arquitetural

- **Estado:** `GameService` estende `ChangeNotifier` — notifica listeners em cada mudança
- **UI Reativa:** `ListenableBuilder` + `setState` + listeners manuais
- **i18n:** `InheritedWidget` (`LocaleProvider`) injeta `Locale` na árvore; `AppStrings` converte
- **Navegação:** `Navigator.pushReplacement` com `MaterialPageRoute` (sem named routes)
- **Áudio:** `audioplayers` ^5.2.1 — `AudioPlayer` com `AssetSource`
- **NENHUM gerenciador de estado externo** (sem Provider, Riverpod, BLoC, GetX)

---

## 📦 Dependências

### Diretas
| Pacote | Versão | Uso |
|--------|--------|-----|
| `flutter` | SDK | Framework |
| `flutter_localizations` | SDK | i18n |
| `audioplayers` | ^5.2.1 | Áudio (música + SFX) |
| `cupertino_icons` | ^1.0.2 | Ícones iOS |

### Dev
| Pacote | Versão | Uso |
|--------|--------|-----|
| `flutter_test` | SDK | Testes |
| `flutter_lints` | ^4.0.0 | Lint |

---

## 🔧 Convenções de Código

### Estilo Geral

- **NUNCA** adicionar comentários no código
- Usar `const` sempre que possível (construtores, widgets, listas)
- Preferir `final` sobre `var` — usar `var` apenas quando o tipo é óbvio
- Nomes de arquivos: `snake_case.dart`
- Nomes de classes: `PascalCase`
- Nomes de métodos/variáveis: `camelCase`
- Nomes de constantes: `camelCase` (seguir Dart style, NÃO `UPPER_CASE`)

### Imports

- Ordem dos imports:
  1. `dart:` (std lib)
  2. `package:` (externos)
  3. `package:super_teclas/` (internos)
  4. Relativos (nunca usar — todos os imports devem ser absolutos com `package:`)
- Separar grupos com linha em branco
- NUNCA usar imports relativos (`import '../...'`)

### Widgets

- `StatefulWidget` para páginas com estado (`HomePage`, `GamePage`, `EndGamePage`)
- `StatelessWidget` para widgets puramente visuais (`ButtonCostumWidget`, `TitleGameWidget`)
- Sempre usar `super.key` no construtor
- NUNCA omitir o parâmetro `key` — sempre `{super.key, ...}`
- Não usar `const` em construtores com parâmetros nomeados obrigatórios

### Material Design

- Usar `Material 3` (`useMaterial3: true`)
- Tema escuro (`Brightness.dark`)
- Cor primária: `Color.fromARGB(255, 3, 73, 131)` — azul escuro
- Botões: `ElevatedButton` com `ButtonStyle` e `WidgetStatePropertyAll`
- NUNCA usar `ThemeData` com parâmetros obsoletos

### Tratamento de Erros

- Usar `try/catch` com discurso vazio (`catch (_) {}`) apenas em casos justificados (ex: `HardwareKeyboard`, `LocaleProvider.of`)
- NUNCA engolir exceções em lógica de negócios

### Navegação

- `Navigator.of(context).pushReplacement(MaterialPageRoute(builder: ...))`
- NUNCA usar `Navigator.pushNamed` ou `onGenerateRoute`
- Callbacks de retorno: `void Function(int? score)? onGameEnd`

---

## 🎮 GameService — Regras de Negócio

### Estado
```
words: List<WordModel>               # Todas as palavras do banco
currentWord: WordModel               # Palavra atual
currentIndex: int                    # Índice da palavra atual
indexWordUseds: List<int>            # Índices já sorteados
isWin: bool                         # true quando todas palavras completadas
totalKeystrokes: int                # Total de teclas digitadas
correctKeystrokes: int              # Teclas corretas
totalWordsCompleted: int            # Palavras completadas
startTime: DateTime?                # Início da partida
```

### Fluxo de Validação
1. `writing(word:)` é chamado em cada `onChanged` do TextFormField
2. Early return se `isWin == true`
3. Ignorar se `word.length != currentWord.text.length`
4. Ignorar se `word != currentWord.text`
5. Incrementar `totalWordsCompleted` e `correctKeystrokes`
6. Se `words.length == indexWordUseds.length + 1` → `isWin = true` + `notifyListeners`
7. Senão, sortear novo índice que não esteja em `indexWordUseds` (loop do-while)

### Cálculos

- **Score:** `switch(indexWordUseds.length)` — 0→0, 1→0, último→100, senão `(n/words.length)*100`
- **Acurácia:** `(correctKeystrokes / totalKeystrokes) * 100` (default 100 se 0)
- **Palavras/minuto:** `(totalWordsCompleted / elapsedSeconds) * 60`
- **Tempo por palavra:** `currentWord.text.length.clamp(8, 15)` segundos
- **Nível:** `score` (passado como `level` para `EndGamePage`)
- **Cor do timer:** verde (>5s), laranja (>3s), vermelho (≤3s)

### Observações Importantes
- `recordKeystroke()` é chamado PARA CADA caractere digitado
- `addCorrectKeystroke()` é chamado PARA CADA caractere correto (pode ser chamado múltiplas vezes pelo mesmo caractere no `onChanged`)
- Método `writing()` NÃO chama `recordKeystroke` ou `addCorrectKeystroke` — isso é feito no `onChanged` do campo
- `startTime` NUNCA é resetado — `wordsPerMinute` considera desde o início da partida

---

## 🌐 Internacionalização (i18n)

### Como funciona
- `AppStrings` recebe `Locale` e expõe getters com tradução condicional
- `AppStrings.from(context)` obtém locale via `Localizations.localeOf(context)`
- `LocaleProvider` é um `InheritedWidget` que wrappa `MaterialApp`
- `localeProvider.onLocaleChanged` atualiza o estado em `MyApp`

### Idiomas
- **Português** (`pt`) — detectado automaticamente via `platformDispatcher.locale`
- **Inglês** (`en`) — fallback padrão
- **Total:** 56 strings cada

### Regras
- Usar `AppStrings.from(context)` para obter strings
- NUNCA hardcodar texto visível ao usuário
- `languageCode` do locale define o idioma
- `Locale` é imutável — troca recria `MaterialApp`

---

## 🔊 Áudio (audioplayers)

### Arquivos
| Arquivo | Tamanho | Uso | Tipo |
|---------|---------|-----|------|
| `stranger-things-124008.mp3` | 5.0 MB | Música de fundo (loop) | `AssetSource` |
| `brass-fanfare-*.mp3` | 327 KB | Vitória (one-shot) | `AssetSource` |
| `fail-144746.mp3` | 130 KB | Derrota (one-shot) | `AssetSource` |

### Configuração
- **Background music:** `setSource + resume`, reinicia em `onPlayerComplete` (loop manual)
- **SFX:** `setSource + resume` one-shot
- **Volume:** 0.3 normal, 0 mutado
- **ReleaseMode:** `ReleaseMode.release`
- **Pause/Resume:** `audioPlayer.pause()` / `audioPlayer.resume()`
- **Mute:** `setVolume(0)` / `setVolume(0.3)`
- **Lifecycle:** Pausar em `AppLifecycleState.paused`, resumir em `resumed`
- **Dispose:** `audioPlayer.dispose()` no `dispose()` do widget

### Regras
- NUNCA usar `AudioCache` — usar diretamente `AudioPlayer().setSource(AssetSource(...))`
- Mock do canal `xyz.audioplayers.source` em testes com `setMockMethodCallHandler`

---

## 🧪 Testes

### Stack
- `flutter_test` com `testWidgets` e `test`
- Mock manual via `TestDefaultBinaryMessengerBinding.setMockMethodCallHandler`
- Localization delegates nos `MaterialApp` de teste
- NUNCA usar `mockito` ou `mocktail`

### Arquivos
| Arquivo | Tipo | Cobertura |
|---------|------|-----------|
| `test/game_service_test.dart` | Unitário | Inicialização, validação (tamanho/texto), avanço, listeners, vitória, unicidade, pós-vitória |
| `test/word_model_test.dart` | Unitário | Trim, preservação, atualização |
| `test/widget_test.dart` | Widget | HomePage: títulos, botão, navegação |
| `test/game_page_test.dart` | Widget | GamePage: interface, pause, mock áudio |
| `test/end_game_page_test.dart` | Widget | EndGamePage: vitória/derrota, score, botões, navegação home |

### Regras
- NUNCA testar implementação de áudio real — SEMPRE mockar o canal
- `pumpAndSettle()` apenas após navegação
- `pump()` para inicialização sem animações
- Agrupar por `group()`:
  - `group('GameService', ...)` para testes unitários
  - `group('HomePage', ...)`, `group('GamePage', ...)`, `group('EndGamePage - Win', ...)` para widget tests
- Helper `_buildApp()` para cada página, nunca reaproveitar helper de outra página

### Comandos
```bash
flutter test                                          # Rodar todos os testes
flutter test test/game_service_test.dart              # Testes unitários específicos
flutter test --coverage && genhtml coverage/lcov.info  # Cobertura
```

---

## 🚀 Deploy

### Vercel
```json
{ "outputDirectory": "build/web" }
```

Passos:
```bash
flutter build web
vercel --prod
```

---

## 🌿 Git

- **Branch ativo:** `develop`
- **Commits:** Mensagens curtas em português, no imperativo
- **NUNCA** commitar sem permissão explícita do usuário
- Verificar `git status`, `git diff` antes de commitar
- NUNCA fazer `git push`, `git commit`, ou criar PRs a menos que o usuário peça

---

## ⚠️ Problemas Conhecidos & Observações

1. **Typo no nome do arquivo:** `button_costum_widget.dart` — "Costum" em vez de "Custom". Classe: `ButtonCostumWidget`. Manter como está para consistência, a menos que o usuário peça correção.
2. **Sem persistência:** High score é apenas em memória (`_highScore` em `_HomePageState`) — perdido ao reiniciar o app.
3. **Sem tratamento de erro de áudio:** Se `audioplayers` falha ao carregar asset, o erro é silencioso.
4. **`onChanged` chama `writing()` a cada tecla:** Mas `writing()` só processa quando `word.length == currentWord.text.length`. Isso significa que `recordKeystroke()` e `addCorrectKeystroke()` são chamados em cada `onChanged`, mas `addCorrectKeystroke()` conta PARA CADA caractere correto no texto inteiro a cada chamada (pode supercontar).
5. **Confete:** Animação customizada com `CustomPainter` (60 partículas), sem pacote externo.
6. **Música de fundo (5MB):** Pode impactar tempo de carregamento inicial, especialmente na Web.
7. **`GameColorStatus`** e **`GameTime`** não são usados em lugar nenhum do código — são utilitários não referenciados.
8. **`impressLevel()`** em `game_page.dart` (linha 366-368) é um método público que só retorna `gameService.score` — provavelmente não utilizado.
9. **`_navigateTo`** em `end_game_page.dart` é uma função tardia (`late`) apenas para permitir `stop()` do áudio antes de navegar.
10. **Navegação com `pushReplacement`** — não há pilha de navegação, todas as transições substituem a rota atual.

---

## 🛠️ Regras para Agentes

### Ao editar código:
1. LER o arquivo antes de editar
2. Seguir TODAS as convenções acima
3. NUNCA adicionar comentários
4. NUNCA adicionar novas dependências sem perguntar ao usuário
5. NUNCA mudar a arquitetura sem consultar
6. Sempre usar `package:` imports absolutos
7. Manter compatibilidade com Dart 3.5+ e Flutter stable
8. NUNCA adicionar gerenciadores de estado externos
9. Preferir `ChangeNotifier` + listeners manuais para estado compartilhado
10. Ao adicionar novos assets, declarar em `pubspec.yaml`

### Ao adicionar novas páginas:
1. Criar em `lib/src/ui/pages/`
2. Estender `StatefulWidget` se tiver estado
3. Usar `super.key`
4. Implementar i18n com `AppStrings.from(context)`
5. Seguir padrão de navegação existente (`pushReplacement`)

### Ao adicionar novos testes:
1. Criar em `test/`
2. Usar `group()` para organizar
3. Mockar canais de áudio com `setMockMethodCallHandler`
4. NUNCA usar pacotes de mock externos
5. Usar `tester.pump()` (não `pumpAndSettle`) para inicialização
6. Helper `_buildApp()` local em cada arquivo de teste

### Ao modificar `GameService`:
1. Manter `ChangeNotifier` como superclasse
2. Chamar `notifyListeners()` após cada mutação relevante
3. NUNCA quebrar a lógica de validação de palavras
4. NUNCA remover a proteção `if (isWin) return;` em `writing()`
5. Manular o loop do-while para sortear índices únicos

### Fluxo de trabalho:
1. Ler arquivo → entender contexto
2. Fazer edições seguindo convenções
3. Rodar `flutter analyze` para verificar lint
4. Rodar `flutter test` para verificar testes
5. NUNCA commitar sem permissão
