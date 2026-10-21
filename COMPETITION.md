# COMPETITION.md — Sistema Inteligente de Competição, Anti-Cheat e Ranking Online (Firebase)

## Visão Geral

Sistema de competição online com **Firebase (Cloud Firestore + Anonymous Auth)** e validação anti-cheat server-side via **Vercel Serverless Functions** no plano 100% gratuito (Firebase Spark + Vercel Hobby).

Permite que jogadores:
1. Registrem um username único associado a uma identidade autenticada (`FirebaseAuth.signInAnonymously`)
2. Carreguem palavras diretamente do Firestore (`words`), cadastradas via endpoint `/api/register-words`
3. Joguem sessões auditadas (`games`) com estados estritos (`running` / Decorrendo, `paused` / Pausado, `finished` / Terminado)
4. Tenham cada palavra registrada com tempo real (`actualDurationMs`) vs tempo esperado (`expectedDurationMs`)
5. Validem a partida no backend (`/api/validate-game`) antes de promover a pontuação ao ranking oficial (`rankings`)

---

## 🏗️ Arquitetura

### Estados do Jogo (`GameStatus`)
- **`running` (Decorrendo):** Único estado que permite digitar e validar palavras ou aumentar pontuação no backend.
- **`paused` (Pausado):** Validado no backend (`action: 'pause'`), congela `remainingWordTimeMs = wordDeadlineAtMs - now`, oculta/desfoca a palavra atual na tela e permite no máximo **3 pausas por partida**.
- **`finished` (Terminado):** Marcado pelo backend quando o `setTimeout` server-side (`wordDeadlineAtMs`) expira, quando todas as palavras são concluídas ou quando a validação detecta fim de tempo; o frontend reage em tempo real via listener `snapshots()` em `games/{gameId}`.

### Coleções do Cloud Firestore
1. **`words/{wordId}`**
   - Campos: `text`, `difficulty` (`easy` | `medium` | `hard`), `definition`, `language` (`pt` | `en`), `length`, `expectedDurationMs`, `updatedAt`
   - Segurança (`firestore.rules`): Leitura pública (`allow read: if true`), criação/atualização validada por schema com dificuldade e idioma válidos.
2. **`sessions/{sessionId}`**
   - Campos: `sessionId`, `userId`, `username`, `usernameLower`, `createdAt`, `updatedAt`
   - Segurança (`firestore.rules`): Isolamento por identificador de sessão local (`sessionId == request.resource.data.sessionId`), garantindo que um jogador não sobrescreva a sessão ou o nome de outro.
3. **`games/{gameId}`**
   - Campos: `gameId`, `userId`, `sessionId`, `username`, `languageCode`, `status` (`running` | `paused` | `finished` | `rejected`), `currentWord` (apenas a palavra atual), `usedWordIds`, `wordSequence`, `wordStartedAtMs`, `wordDeadlineAtMs`, `remainingWordTimeMs`, `score`, `wordsCompleted`, `accuracy`, `averageSpeed`, `pauseCount`, `totalPausedDurationMs`, `startedAt`, `finishedAt`, `wordsLog`, `validated`
   - Segurança (`firestore.rules`): Transições estritas de estado (`running` / `paused` / `finished`), máximo de 3 pausas e congelamento de pontuação fora do estado `running`.
4. **`rankings/{rankingId}`**
   - Campos: `userId`, `sessionId`, `username`, `score`, `words_completed`, `accuracy`, `average_speed`, `gameId`, `created_at`, `updatedAt`
   - Segurança (`firestore.rules`): Leitura pública, escrita estritamente monotonicamente crescente e vinculada à sessão proprietária.

---

## 🛡️ Endpoints Serverless & Anti-Cheat

### 1. `POST /api/register-words`
- Protegido por `Authorization: Bearer <ADMIN_SEED_TOKEN>`
- Recebe `{ language: "pt" | "en", words: [...] }`
- Calcula `expectedDurationMs` determinístico por tamanho e dificuldade e grava em lotes (`WriteBatch`) na coleção `words`.
- Script CLI incluído:
  ```bash
  API_BASE_URL=https://your-project.vercel.app ADMIN_SEED_TOKEN=your-secret-token npm run seed:words
  ```

### 2. `POST /api/game-session` (Server-Authoritative Game Loop)
- Protegido por `Authorization: Bearer <Firebase ID Token>`
- Suporta as ações:
  - **`start`:** Cria `games/{gameId}` no Firestore via Admin SDK, sorteia e envia **apenas 1 palavra** (`currentWord`), define `wordDeadlineAtMs = now + allowedTimeMs` (8s–15s) e agenda um `setTimeout` server-side (`waitUntil`) que verifica o documento após o prazo e encerra o jogo (`status = 'finished'`) automaticamente se o jogador não tiver avançado nem pausado.
  - **`submit`:** Recebe `{ gameId, word, accuracy }`, valida que `status == 'running'`, verifica `now <= wordDeadlineAtMs + 300ms` (tolerância de rede), valida texto da palavra e limite biomecânico (`actualDurationMs >= length * 40`), calcula pontos (`easy = 100`, `medium = 150`, `hard = 200` + bônus de velocidade), grava em `wordsLog`, sorteia a próxima palavra única e agenda o próximo `setTimeout` server-side.
  - **`pause` / `resume`:** Valida limite máximo de 3 pausas, congela `remainingWordTimeMs` ao pausar e reagenda `wordDeadlineAtMs` e o `setTimeout` ao retomar.
  - **`timeout`:** Verifica/força encerramento por tempo esgotado (`status = 'finished'`) e promove a pontuação para `rankings/{username}` se `score > 0`.

### 3. `POST /api/validate-game`
- Endpoint de auditoria/finalização ao término da partida (`{ gameId, username, accuracy }`), garantindo recálculo server-side e promoção ao ranking oficial (`rankings/{username}`).

---

## 🔧 Configuração Sem Chaves no Repositório (Zero Secrets)

Nenhuma chave ou credencial fica salva no código-fonte.

### Desenvolvimento Local
Copie `.env.example` para `.env` (ignorado pelo Git):
```env
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_APP_ID=your-firebase-app-id
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_MESSAGING_SENDER_ID=your-messaging-sender-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
API_BASE_URL=https://your-project.vercel.app
ADMIN_SEED_TOKEN=your-secret-admin-seed-token
```

### GitHub Actions & Vercel Secrets
Configure os secrets no repositório GitHub (`Settings → Secrets and variables → Actions`):
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_AUTH_DOMAIN`
- `API_BASE_URL`
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`

E no painel da Vercel (`Project Settings → Environment Variables`):
- `FIREBASE_SERVICE_ACCOUNT_JSON` (ou `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`)
- `ADMIN_SEED_TOKEN`
