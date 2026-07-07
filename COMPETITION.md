# COMPETITION.md — Sistema de Competição e Ranking Online

## Visão Geral

Sistema de ranking online com Supabase para o Super Teclas. Permite que jogadores:
1. Registrem um username único (armazenado localmente)
2. Compitam por pontuação máxima no ranking global
3. Vejam o top 10 diretamente na HomePage
4. Joguem offline sem perder funcionalidade

---

## 🏗️ Arquitetura

### Fluxo de Dados

```
[HomePage]
    ├── Sem username salvo → exibe campo + botão "Save"
    ├── Com username salvo  → exibe nick (só leitura)
    └── Ranking section    → top scores do Supabase (se disponível)

[GamePage] → [EndGamePage] → submitScore() → [Supabase]
                                    │
                                    └── falha silenciosa se offline
```

### Camadas

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Serviço | `lib/src/services/storage_service.dart` | Persistência local do username |
| Serviço | `lib/src/services/ranking_service.dart` | Comunicação com Supabase (CRUD ranking) |
| UI | `lib/src/ui/pages/home_page.dart` | Input/display username + ranking section |
| UI | `lib/src/ui/pages/end_game_page.dart` | Submissão de score ao fim do jogo |
| Data | `assets/words/pt.json` | Palavras PT com dificuldade (~200) |
| Data | `assets/words/en.json` | Palavras EN com dificuldade (~200) |

### Modelo de Dados — Supabase (tabela `rankings`)

```sql
CREATE TABLE rankings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  username TEXT NOT NULL,
  score INT NOT NULL,
  words_completed INT DEFAULT 0,
  accuracy REAL DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para consulta rápida do top scores
CREATE INDEX idx_rankings_score ON rankings (score DESC);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_rankings_updated_at
  BEFORE UPDATE ON rankings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔧 Configuração

### 1. Supabase

1. Criar projeto em [supabase.com](https://supabase.com)
2. Executar o SQL acima no **SQL Editor** para criar a tabela `rankings`
3. Ir em **Settings → API** e copiar:
   - `Project URL`
   - `anon public key` (também chamado `publishableKey`)

### 2. Código

Em `lib/main.dart:4-5`, substituir os placeholders:

```dart
const _supabaseUrl = 'https://your-project.supabase.co';    // ← colocar URL real
const _supabaseAnonKey = 'your-anon-key';                    // ← colocar anon key real
```

### 3. Row Level Security (RLS)

Recomendado para proteção dos dados. No SQL Editor:

```sql
-- Habilitar RLS
ALTER TABLE rankings ENABLE ROW LEVEL SECURITY;

-- Política: qualquer um pode inserir (anon)
CREATE POLICY "Anyone can insert rankings"
  ON rankings FOR INSERT
  TO anon
  WITH CHECK (true);

-- Política: qualquer um pode ler rankings
CREATE POLICY "Anyone can read rankings"
  ON rankings FOR SELECT
  TO anon
  USING (true);

-- Política: apenas updates pelo próprio username (opcional)
CREATE POLICY "Users can update their own rankings"
  ON rankings FOR UPDATE
  TO anon
  USING (username = current_setting('request.jwt.claims')::json->>'username');
```

> **Atenção:** As políticas acima são para desenvolvimento. Em produção, considerar autenticação real com `supabase.auth` em vez de confiar no `anon key` para escrita.

---

## 🛡️ Segurança

### Riscos Identificados

| Risco | Gravidade | Mitigação |
|-------|-----------|-----------|
| Injeção de score falso via anon key | Alta | Validar score no backend via Edge Function ou RLS com hash |
| Username duplicado | Baixa | Aceitável para MVP; futuramente Unique constraint + auth |
| Exposição da anon key no frontend | Média | Anon key é **pública por design** no Supabase; risco é controlado por RLS |
| Interceptação de dados | Baixa | Supabase usa HTTPS obrigatório |

### Boas Práticas

- **NUNCA** colocar `service_role key` no frontend (apenas server-side)
- **Sempre** usar RLS para restringir operações
- **NUNCA** expor secrets no código (a anon key é a exceção — é pública)
- Em produção, substituir `anon key` + escrita direta por **Edge Functions** autenticadas

### Limitações Atuais

- `RankingService.submitScore()` usa o client anon — qualquer um pode enviar scores
- Sem validação server-side do score (Edge Function)
- Username não tem unique constraint no Supabase (mas o StorageService impede troca após salvo)

---

## 🧪 Testes

### Mock do Supabase

Para testar sem conexão real, usar `setMockMethodCallHandler` no canal do Supabase:

```dart
// Em setUpAll:
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(
  const MethodChannel('com.supabase'),
  (methodCall) async {
    switch (methodCall.method) {
      case 'select':
        return [
          {'username': 'Player1', 'score': 90, 'words_completed': 40, 'accuracy': 95.0, 'created_at': '2026-01-01T00:00:00Z'},
        ];
      case 'insert':
        return null;
      default:
        return null;
    }
  },
);
```

### O que Testar

- `StorageService.getUsername()` / `saveUsername()` — persistência local
- `RankingService.submitScore()` — falha silenciosa offline, sucesso online
- `RankingService.getRankings()` — retorna lista vazia offline, dados online
- HomePage: exibe campo username quando não salvo, exibe nick quando salvo
- HomePage: ranking section aparece apenas se houver dados
- EndGamePage: `_submitRanking()` é chamado no initState

---

## 📦 Dependências Adicionadas

| Pacote | Versão | Uso |
|--------|--------|-----|
| `shared_preferences` | ^2.2.0 | Persistência local do username |
| `supabase_flutter` | ^2.6.0 | Cliente Supabase para ranking online |

### Porquê `shared_preferences`?

- Já é dependência transitiva de `supabase_flutter` (via `path_provider`)
- API síncrona assíncrona simples (`getString`/`setString`)
- Funciona em todas as plataformas (Android, iOS, Web, Linux, Windows, macOS)

---

## 🆕 Novos Arquivos

| Arquivo | Tipo | Linhas | Descrição |
|---------|------|--------|-----------|
| `assets/words/pt.json` | Asset | ~200 | Palavras PT com dificuldade (easy/medium/hard) |
| `assets/words/en.json` | Asset | ~200 | Palavras EN com dificuldade (easy/medium/hard) |
| `lib/src/services/storage_service.dart` | Serviço | ~20 | Get/set username via SharedPreferences |
| `lib/src/services/ranking_service.dart` | Serviço | ~70 | Submit/get rankings via Supabase |

## 📄 Arquivos Modificados

| Arquivo | Mudança |
|---------|---------|
| `pubspec.yaml` | + `shared_preferences`, + `supabase_flutter`, + `assets/words/` |
| `lib/main.dart` | + Supabase.initialize, + SharedPreferences init, + WordBank.load, + TODO para credenciais |
| `lib/src/data/models/word_model.dart` | + campo `difficulty` |
| `lib/src/data/words/word_bank.dart` | Agora carrega de JSON (fallback hardcoded se falhar) |
| `lib/src/services/game_service.dart` | + `languageCode` no construtor; usa `WordModel.difficulty` |
| `lib/src/ui/pages/home_page.dart` | + username section, + ranking section, + StorageService |
| `lib/src/ui/pages/game_page.dart` | + `languageCode` param, passa `totalWordsCompleted` e `accuracy` para EndGamePage |
| `lib/src/ui/pages/end_game_page.dart` | + `totalWordsCompleted`, + `accuracy` params, + `_submitRanking()` ao init |

---

## 📋 Fluxo Completo

```
1. App inicia
   ├── Supabase.initialize(url, anonKey)
   ├── SharedPreferences.getInstance()
   └── WordBank.load(languageCode)  ← carrega JSON com ~200 palavras

2. HomePage
   ├── Carrega username do StorageService
   ├── Se não tem username:
   │     └── Exibe TextFormField + botão Save
   ├── Se tem username:
   │     └── Exibe nick (azul, bold, só leitura)
   ├── Carrega rankings do RankingService (se online)
   └── Exibe ranking section com top 10 (se houver dados)

3. GamePage
   ├── GameService(languageCode: ...)
   └── Ao terminar (vitória ou tempo):
         └── Navega para EndGamePage com score, wordsCompleted, accuracy

4. EndGamePage
   ├── Toca som (vitória/derrota)
   ├── _submitRanking()
   │     ├── Lê username do StorageService
   │     ├── Se tem username → RankingService.submitScore()
   │     └── Se não tem → silencia (jogador anônimo)
   └── Exibe resultado + botões Recomeçar/Início
```

---

## ⚠️ Observações

1. **Username sem edição:** Uma vez salvo, não há UI para alterar. Para trocar, apagar `SharedPreferences` manualmente.
2. **Ranking offline:** Se Supabase não estiver disponível, `RankingService` retorna lista vazia e falha silenciosamente — o jogo funciona normalmente.
3. **Anon key pública:** A `anon key` do Supabase é feita para ser pública no frontend. A segurança vem do RLS, não da chave.
4. **Sem autenticação:** O sistema atual não usa `supabase.auth`. Futuramente, integrar login para garantir unicidade de username e segurança nos scores.
5. **Palavras em JSON:** Novas palavras podem ser adicionadas editando `pt.json` e `en.json`. O formato é `[{"word": "...", "difficulty": "easy|medium|hard"}]`.
6. **WordBank fallback:** Se o JSON não carregar (asset faltando), o `WordBank` usa uma lista hardcoded de 16 palavras de fallback.

---

## 🔮 Melhorias Futuras

- [ ] **Edge Function** server-side para validar scores antes de inserir
- [ ] **Autenticação Supabase Auth** para users reais (Google, GitHub, Email)
- [ ] **Página de ranking dedicada** com paginação e posição do jogador
- [ ] **Unique constraint** no username (com validação no registro)
- [ ] **Sistema de dificuldade** baseado nas palavras escolhidas (easy/medium/hard)
- [ ] **Filtro de ranking** por idioma (PT / EN)
