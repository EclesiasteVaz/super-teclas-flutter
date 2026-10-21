const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const NETWORK_GRACE_MS = 300;
const MAX_PAUSES = 3;
const WORDS_CACHE_TTL_MS = 10 * 60 * 1000;

const wordsCache = {
  pt: { words: [], loadedAt: 0 },
  en: { words: [], loadedAt: 0 },
};

const FALLBACK_WORDS = {
  pt: [
    { text: 'Computador', difficulty: 'medium', definition: 'Máquina eletrônica de processamento de dados' },
    { text: 'Telefone', difficulty: 'easy', definition: 'Aparelho de telecomunicação' },
    { text: 'Democracia', difficulty: 'medium', definition: 'Regime político baseado na soberania popular' },
    { text: 'Programação', difficulty: 'medium', definition: 'Escrita de código para computadores' },
    { text: 'Engenharia', difficulty: 'medium', definition: 'Aplicação de conhecimentos científicos e técnicos' },
    { text: 'Desenvolvimento', difficulty: 'hard', definition: 'Ação ou efeito de desenvolver' },
    { text: 'Responsabilidade', difficulty: 'hard', definition: 'Obrigação de responder pelas próprias ações' },
    { text: 'Paralelepípedo', difficulty: 'hard', definition: 'Prisma de seis faces paralelogrâmicas' },
  ],
  en: [
    { text: 'Computer', difficulty: 'easy', definition: 'Electronic data processing machine' },
    { text: 'Telephone', difficulty: 'medium', definition: 'Telecommunications device' },
    { text: 'Democracy', difficulty: 'medium', definition: 'Government by the whole population' },
    { text: 'Programming', difficulty: 'medium', definition: 'Writing computer programs' },
    { text: 'Engineering', difficulty: 'medium', definition: 'Branch of science and technology' },
    { text: 'Development', difficulty: 'medium', definition: 'Process of developing or being developed' },
    { text: 'Responsibility', difficulty: 'hard', definition: 'State or fact of having a duty' },
    { text: 'Thermodynamics', difficulty: 'hard', definition: 'Branch of physical science' },
  ],
};

function initFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }

  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    }),
  });
}

function sanitizeDocId(language, text) {
  const normalized = String(text || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\u00C0-\u017F_-]/gi, '_');
  return `${language}_${normalized}`;
}

function calculateExpectedDurationMs(text, difficulty) {
  const trimmed = String(text || '').trim();
  const diff = String(difficulty || 'medium').toLowerCase();
  const factor = diff === 'easy' ? 350 : diff === 'hard' ? 450 : 400;
  return Math.min(Math.max(trimmed.length * factor, 1200), 15000);
}

function calculateBasePoints(difficulty) {
  const diff = String(difficulty || 'medium').toLowerCase();
  if (diff === 'easy') return 100;
  if (diff === 'hard') return 200;
  return 150;
}

function calculateWordPoints(difficulty, expectedDurationMs, actualDurationMs) {
  const basePoints = calculateBasePoints(difficulty);
  if (
    actualDurationMs <= 0 ||
    expectedDurationMs <= 0 ||
    actualDurationMs >= expectedDurationMs
  ) {
    return basePoints;
  }
  const maxBonus = Math.floor(basePoints / 2);
  const ratio = (expectedDurationMs - actualDurationMs) / expectedDurationMs;
  const bonus = Math.min(Math.max(Math.round(ratio * maxBonus), 0), maxBonus);
  return basePoints + bonus;
}

function getAllowedWordTimeMs(text) {
  const len = String(text || '').trim().length;
  const clampedSeconds = Math.min(Math.max(len, 8), 15);
  return clampedSeconds * 1000;
}

function normalizeWordObject(raw, language, docId) {
  const text = String(raw.text || raw.word || '').trim();
  if (!text) return null;
  const diffRaw = String(raw.difficulty || 'medium').toLowerCase();
  const difficulty = ['easy', 'medium', 'hard'].includes(diffRaw) ? diffRaw : 'medium';
  const definition = String(raw.definition || '').trim();
  const expectedDurationMs =
    Number(raw.expectedDurationMs) > 0
      ? Number(raw.expectedDurationMs)
      : calculateExpectedDurationMs(text, difficulty);

  return {
    id: docId || raw.id || sanitizeDocId(language, text),
    text,
    difficulty,
    definition,
    language,
    length: text.length,
    expectedDurationMs,
  };
}

async function loadWordsForLanguage(db, rawLang) {
  const language = rawLang === 'en' ? 'en' : 'pt';
  const now = Date.now();
  const cached = wordsCache[language];
  if (cached && cached.words.length > 0 && now - cached.loadedAt < WORDS_CACHE_TTL_MS) {
    return cached.words;
  }

  try {
    const snap = await db
      .collection('words')
      .where('language', '==', language)
      .get();

    if (!snap.empty) {
      const firestoreWords = [];
      snap.forEach((doc) => {
        const w = normalizeWordObject(doc.data(), language, doc.id);
        if (w) firestoreWords.push(w);
      });
      if (firestoreWords.length > 0) {
        wordsCache[language] = { words: firestoreWords, loadedAt: now };
        return firestoreWords;
      }
    }
  } catch (_) {}

  try {
    const filePath = path.join(process.cwd(), 'scripts', 'words', `${language}.json`);
    const rawJson = fs.readFileSync(filePath, 'utf8');
    const parsed = JSON.parse(rawJson);
    if (Array.isArray(parsed)) {
      const assetWords = parsed
        .map((item) => normalizeWordObject(item, language))
        .filter(Boolean);
      if (assetWords.length > 0) {
        wordsCache[language] = { words: assetWords, loadedAt: now };
        return assetWords;
      }
    }
  } catch (_) {}

  const fallback = (FALLBACK_WORDS[language] || FALLBACK_WORDS.pt)
    .map((item) => normalizeWordObject(item, language))
    .filter(Boolean);
  wordsCache[language] = { words: fallback, loadedAt: now };
  return fallback;
}

function canSessionUpdateRanking(existingData, game) {
  if (!existingData) return true;
  const existingSessionId = String(existingData.sessionId || '').trim();
  const gameSessionId = String(game.sessionId || '').trim();
  if (existingSessionId && gameSessionId) {
    return existingSessionId === gameSessionId;
  }
  const existingUserId = String(existingData.userId || '').trim();
  const gameUserId = String(game.userId || '').trim();
  if (
    existingUserId &&
    existingUserId !== 'anonymous' &&
    gameUserId &&
    gameUserId !== 'anonymous'
  ) {
    return existingUserId === gameUserId;
  }
  return true;
}

async function promoteScoreToRankingIfEligible(db, game, finalScore) {
  const username = String(game.username || '').trim();
  const score = Number(finalScore ?? game.score ?? 0);
  if (!username || score <= 0) return;

  const rankingId = username.toLowerCase();
  const rankingRef = db.collection('rankings').doc(rankingId);
  const existingSnap = await rankingRef.get();
  const existingData = existingSnap.exists ? existingSnap.data() : null;

  if (!canSessionUpdateRanking(existingData, game)) {
    return;
  }

  if (!existingSnap.exists || Number(existingData.score || 0) < score) {
    await rankingRef.set(
      {
        sessionId: String(game.sessionId || game.userId || 'anonymous'),
        userId: game.userId || 'anonymous',
        username,
        usernameLower: rankingId,
        score,
        words_completed: Number(game.wordsCompleted || 0),
        accuracy: Number(game.accuracy ?? 100),
        average_speed: Number(game.averageSpeed || 0),
        gameId: game.gameId,
        created_at: new Date().toISOString(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
}

async function finalizeGameAsTimedOut(db, gameRef, game, nowMs, accuracyOverride) {
  const accuracy =
    accuracyOverride !== undefined
      ? Math.min(Math.max(Number(accuracyOverride) || 100, 0), 100)
      : Number(game.accuracy ?? 100);
  const finalScore = Number(game.score || 0);

  await gameRef.update({
    status: 'finished',
    isWin: false,
    terminationReason: 'timeout',
    expiredWordSequence: Number(game.wordSequence || 1),
    accuracy,
    validated: true,
    validatedScore: finalScore,
    wordDeadlineAt: null,
    wordDeadlineAtMs: null,
    finishedAtMs: nowMs,
    finishedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await promoteScoreToRankingIfEligible(
    db,
    { ...game, accuracy },
    finalScore
  );
}

async function expireGameIfDeadlinePassed(db, gameId, expectedWordSequence) {
  const gameRef = db.collection('games').doc(gameId);
  const snap = await gameRef.get();
  if (!snap.exists) return false;

  const game = snap.data();
  if (game.status !== 'running') return false;
  if (
    expectedWordSequence !== undefined &&
    Number(game.wordSequence || 1) !== Number(expectedWordSequence)
  ) {
    return false;
  }

  const nowMs = Date.now();
  const deadlineMs = Number(game.wordDeadlineAtMs || 0);
  if (!deadlineMs || nowMs < deadlineMs) {
    return false;
  }

  await finalizeGameAsTimedOut(db, gameRef, game, nowMs);
  return true;
}

function runInBackground(promise) {
  try {
    const ctxSymbol = Symbol.for('@vercel/request-context');
    const ctx = globalThis[ctxSymbol]?.get?.();
    if (ctx && typeof ctx.waitUntil === 'function') {
      ctx.waitUntil(promise);
      return;
    }
  } catch (_) {}
  promise.catch(() => {});
}

function scheduleServerWordTimeout({ db, gameId, wordSequence, delayMs }) {
  const clampedDelay = Math.min(Math.max(Number(delayMs) || 8000, 1), 16000);
  const waitMs = clampedDelay + NETWORK_GRACE_MS;

  const timeoutPromise = new Promise((resolve) => {
    const timer = setTimeout(async () => {
      try {
        await expireGameIfDeadlinePassed(db, gameId, wordSequence);
      } catch (_) {
      } finally {
        resolve();
      }
    }, waitMs);

    if (typeof timer.unref === 'function' && process.env.NODE_ENV === 'test') {
      timer.unref();
    }
  });

  runInBackground(timeoutPromise);
  return timeoutPromise;
}

async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    initFirebaseAdmin();
    const db = admin.firestore();

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const action = String(body.action || '').trim().toLowerCase();

    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7).trim()
      : String(body.idToken || '').trim();

    if (!token) {
      return res.status(401).json({ error: 'Authentication token is required' });
    }

    let verifiedUid = null;
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      verifiedUid = decoded.uid;
    } catch (_) {
      return res.status(401).json({ error: 'Invalid or expired authentication token' });
    }

    const nowMs = Date.now();

    if (action === 'start') {
      const languageCode = body.languageCode === 'en' ? 'en' : 'pt';
      const username = String(body.username || '').trim();
      const sessionId = String(body.sessionId || verifiedUid || '').trim();
      const initialWordId = String(body.initialWordId || '').trim();
      const wordsPool = await loadWordsForLanguage(db, languageCode);
      const matchedInitialWord = initialWordId
        ? wordsPool.find((w) => w.id === initialWordId || w.text === initialWordId)
        : null;
      const randomIndex = Math.floor(Math.random() * wordsPool.length);
      const firstWord = matchedInitialWord || wordsPool[randomIndex];
      const allowedTimeMs = getAllowedWordTimeMs(firstWord.text);
      const wordDeadlineAtMs = nowMs + allowedTimeMs;
      const wordStartedAtIso = new Date(nowMs).toISOString();
      const wordDeadlineAtIso = new Date(wordDeadlineAtMs).toISOString();

      const gameRef = db.collection('games').doc();
      const gameDoc = {
        gameId: gameRef.id,
        sessionId: sessionId || verifiedUid,
        userId: verifiedUid,
        username,
        usernameLower: username.toLowerCase(),
        languageCode,
        status: 'running',
        isWin: false,
        score: 0,
        validatedScore: 0,
        lastWordPoints: 0,
        wordsCompleted: 0,
        totalWordsPool: wordsPool.length,
        accuracy: 100,
        averageSpeed: 0,
        pauseCount: 0,
        totalPausedDurationMs: 0,
        currentWordPausedMs: 0,
        pauseStartedAtMs: null,
        currentWord: firstWord,
        usedWordIds: [firstWord.id],
        wordSequence: 1,
        wordStartedAt: wordStartedAtIso,
        wordStartedAtMs: nowMs,
        wordDeadlineAt: wordDeadlineAtIso,
        wordDeadlineAtMs,
        remainingWordTimeMs: allowedTimeMs,
        wordsLog: [],
        validated: false,
        startedAtMs: nowMs,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await gameRef.set(gameDoc);

      scheduleServerWordTimeout({
        db,
        gameId: gameRef.id,
        wordSequence: 1,
        delayMs: allowedTimeMs,
      });

      return res.status(200).json({
        gameId: gameRef.id,
        status: 'running',
        isWin: false,
        expired: false,
        currentWord: firstWord,
        wordSequence: 1,
        totalWordsPool: wordsPool.length,
        allowedTimeMs,
        remainingTimeMs: allowedTimeMs,
        serverNowMs: nowMs,
        wordStartedAt: wordStartedAtIso,
        wordStartedAtMs: nowMs,
        wordDeadlineAt: wordDeadlineAtIso,
        wordDeadlineAtMs,
        score: 0,
        lastWordPoints: 0,
        wordsCompleted: 0,
        pauseCount: 0,
        remainingPauses: MAX_PAUSES,
        averageSpeed: 0,
      });
    }

    const gameId = String(body.gameId || '').trim();
    if (!gameId) {
      return res.status(400).json({ error: 'gameId is required' });
    }

    const gameRef = db.collection('games').doc(gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      return res.status(404).json({ error: 'Game session not found' });
    }

    const game = gameSnap.data();

    if (game.userId && game.userId !== verifiedUid) {
      return res.status(403).json({ error: 'Game userId does not match authenticated user' });
    }

    if (game.status === 'finished' || game.status === 'rejected') {
      return res.status(200).json({
        gameId,
        status: game.status,
        isWin: Boolean(game.isWin),
        expired: game.terminationReason === 'timeout',
        score: Number(game.score || 0),
        lastWordPoints: Number(game.lastWordPoints || 0),
        wordsCompleted: Number(game.wordsCompleted || 0),
        pauseCount: Number(game.pauseCount || 0),
        remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
        averageSpeed: Number(game.averageSpeed || 0),
      });
    }

    if (
      game.status === 'running' &&
      game.wordDeadlineAtMs &&
      nowMs > Number(game.wordDeadlineAtMs) + NETWORK_GRACE_MS
    ) {
      await finalizeGameAsTimedOut(db, gameRef, game, nowMs, body.accuracy);
      return res.status(200).json({
        gameId,
        status: 'finished',
        isWin: false,
        expired: true,
        score: Number(game.score || 0),
        lastWordPoints: Number(game.lastWordPoints || 0),
        wordsCompleted: Number(game.wordsCompleted || 0),
        pauseCount: Number(game.pauseCount || 0),
        remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
        averageSpeed: Number(game.averageSpeed || 0),
      });
    }

    if (action === 'timeout' || action === 'check_timeout') {
      if (game.status === 'running') {
        const currentSequence = Number(game.wordSequence || 1);
        const requestedSequence =
          body.wordSequence !== undefined ? Number(body.wordSequence) : currentSequence;
        const deadlineMs = Number(game.wordDeadlineAtMs || 0);
        const sequenceMatches = requestedSequence === currentSequence;
        const forceClientTimeout =
          sequenceMatches &&
          body.reason === 'client_timer_expired' &&
          (!deadlineMs || nowMs >= deadlineMs - 1500);

        if (
          sequenceMatches &&
          (forceClientTimeout || !deadlineMs || nowMs >= deadlineMs)
        ) {
          await finalizeGameAsTimedOut(db, gameRef, game, nowMs, body.accuracy);
          return res.status(200).json({
            gameId,
            status: 'finished',
            isWin: false,
            expired: true,
            score: Number(game.score || 0),
            wordsCompleted: Number(game.wordsCompleted || 0),
            pauseCount: Number(game.pauseCount || 0),
            averageSpeed: Number(game.averageSpeed || 0),
          });
        }
        return res.status(200).json({
          gameId,
          status: 'running',
          isWin: false,
          expired: false,
          currentWord: game.currentWord,
          wordSequence: currentSequence,
          remainingTimeMs: Math.max(0, deadlineMs - nowMs),
          serverNowMs: nowMs,
          wordDeadlineAtMs: deadlineMs,
          score: Number(game.score || 0),
          wordsCompleted: Number(game.wordsCompleted || 0),
        });
      }
      return res.status(200).json({
        gameId,
        status: game.status,
        isWin: Boolean(game.isWin),
        expired: false,
        score: Number(game.score || 0),
        wordsCompleted: Number(game.wordsCompleted || 0),
      });
    }

    if (action === 'pause') {
      if (game.status !== 'running') {
        return res.status(409).json({
          error: 'Game must be in running state to pause',
          status: game.status,
        });
      }

      const deadlineMs = Number(game.wordDeadlineAtMs || 0);
      if (deadlineMs > 0 && nowMs > deadlineMs) {
        await finalizeGameAsTimedOut(db, gameRef, game, nowMs, body.accuracy);
        return res.status(200).json({
          gameId,
          status: 'finished',
          isWin: false,
          expired: true,
          score: Number(game.score || 0),
          lastWordPoints: Number(game.lastWordPoints || 0),
          wordsCompleted: Number(game.wordsCompleted || 0),
          pauseCount: Number(game.pauseCount || 0),
          remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
          averageSpeed: Number(game.averageSpeed || 0),
        });
      }

      const currentPauses = Number(game.pauseCount || 0);
      if (currentPauses >= MAX_PAUSES) {
        return res.status(422).json({
          error: 'Maximum allowed pauses (3) exceeded',
          status: game.status,
          pauseCount: currentPauses,
          remainingPauses: 0,
        });
      }

      const effectiveDeadlineMs = deadlineMs > 0 ? deadlineMs : nowMs + 8000;
      const remainingWordTimeMs = Math.max(1, effectiveDeadlineMs - nowMs);
      const newPauseCount = currentPauses + 1;

      await gameRef.update({
        status: 'paused',
        pauseCount: newPauseCount,
        pauseStartedAtMs: nowMs,
        remainingWordTimeMs,
        wordDeadlineAt: null,
        wordDeadlineAtMs: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        gameId,
        status: 'paused',
        isWin: false,
        expired: false,
        pauseCount: newPauseCount,
        remainingPauses: MAX_PAUSES - newPauseCount,
        remainingTimeMs: remainingWordTimeMs,
        serverNowMs: nowMs,
        score: Number(game.score || 0),
        wordsCompleted: Number(game.wordsCompleted || 0),
      });
    }

    if (action === 'resume') {
      if (game.status !== 'paused') {
        return res.status(409).json({
          error: 'Game must be in paused state to resume',
          status: game.status,
        });
      }

      const pauseStartedAtMs = Number(game.pauseStartedAtMs || nowMs);
      const pausedDurationMs = Math.max(0, nowMs - pauseStartedAtMs);
      const newTotalPausedDurationMs =
          Number(game.totalPausedDurationMs || 0) + pausedDurationMs;
      const newCurrentWordPausedMs =
          Number(game.currentWordPausedMs || 0) + pausedDurationMs;
      const remainingWordTimeMs = Math.max(
        1,
        Number(game.remainingWordTimeMs || 8000)
      );
      const newDeadlineAtMs = nowMs + remainingWordTimeMs;
      const newDeadlineAtIso = new Date(newDeadlineAtMs).toISOString();
      const currentSequence = Number(game.wordSequence || 1);

      await gameRef.update({
        status: 'running',
        pauseStartedAtMs: null,
        totalPausedDurationMs: newTotalPausedDurationMs,
        currentWordPausedMs: newCurrentWordPausedMs,
        wordDeadlineAt: newDeadlineAtIso,
        wordDeadlineAtMs: newDeadlineAtMs,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      scheduleServerWordTimeout({
        db,
        gameId,
        wordSequence: currentSequence,
        delayMs: remainingWordTimeMs,
      });

      return res.status(200).json({
        gameId,
        status: 'running',
        isWin: false,
        expired: false,
        currentWord: game.currentWord,
        wordSequence: currentSequence,
        pauseCount: Number(game.pauseCount || 0),
        remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
        remainingTimeMs: remainingWordTimeMs,
        serverNowMs: nowMs,
        wordDeadlineAt: newDeadlineAtIso,
        wordDeadlineAtMs: newDeadlineAtMs,
        score: Number(game.score || 0),
        wordsCompleted: Number(game.wordsCompleted || 0),
      });
    }

    if (action === 'submit' || action === 'submit_word') {
      if (game.status !== 'running') {
        return res.status(409).json({
          error: 'Cannot submit word while game is not running',
          status: game.status,
        });
      }

      const typedWord = String(body.word || body.typedWord || '').trim();
      const activeWord = game.currentWord;

      if (!activeWord || !activeWord.text) {
        return res.status(422).json({ error: 'No active word in session' });
      }

      const expectedText = String(activeWord.text).trim();
      if (typedWord !== expectedText) {
        return res.status(422).json({
          valid: false,
          status: 'running',
          error: 'Submitted word does not match current word',
        });
      }

      const wordStartedAtMs = Number(game.wordStartedAtMs || nowMs);
      const currentWordPausedMs = Number(game.currentWordPausedMs || 0);
      const actualDurationMs = Math.max(
        1,
        nowMs - wordStartedAtMs - currentWordPausedMs
      );
      const minHumanDurationMs = expectedText.length * 40;

      if (actualDurationMs < minHumanDurationMs) {
        const reason = `Biomechanical speed limit violated for word "${expectedText}" (${actualDurationMs}ms < ${minHumanDurationMs}ms)`;
        await gameRef.update({
          status: 'rejected',
          validated: false,
          rejectionReason: reason,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.status(422).json({
          valid: false,
          status: 'rejected',
          reason,
        });
      }

      const expectedDurationMs =
        Number(activeWord.expectedDurationMs) > 0
          ? Number(activeWord.expectedDurationMs)
          : calculateExpectedDurationMs(expectedText, activeWord.difficulty);

      const wordPoints = calculateWordPoints(
        activeWord.difficulty,
        expectedDurationMs,
        actualDurationMs
      );

      const newScore = Number(game.score || 0) + wordPoints;
      const logEntry = {
        wordId: activeWord.id || sanitizeDocId(game.languageCode || 'pt', expectedText),
        wordText: expectedText,
        difficulty: activeWord.difficulty || 'medium',
        length: expectedText.length,
        expectedDurationMs,
        actualDurationMs,
        startedAt: new Date(wordStartedAtMs).toISOString(),
        completedAt: new Date(nowMs).toISOString(),
        stateWhenTyped: 'running',
        pointsAwarded: wordPoints,
      };

      const wordsLog = Array.isArray(game.wordsLog)
        ? [...game.wordsLog, logEntry]
        : [logEntry];
      const newWordsCompleted = wordsLog.length;
      const sumActualDurationMs = wordsLog.reduce(
        (sum, entry) => sum + Number(entry.actualDurationMs || 0),
        0
      );
      const averageSpeed = Number(
        (sumActualDurationMs / newWordsCompleted / 1000).toFixed(2)
      );
      const accuracy =
        body.accuracy !== undefined
          ? Math.min(Math.max(Number(body.accuracy) || 100, 0), 100)
          : Number(game.accuracy ?? 100);

      const wordsPool = await loadWordsForLanguage(db, game.languageCode || 'pt');
      const usedWordIds = Array.isArray(game.usedWordIds)
        ? [...game.usedWordIds]
        : [logEntry.wordId];
      if (!usedWordIds.includes(logEntry.wordId)) {
        usedWordIds.push(logEntry.wordId);
      }

      const unusedWords = wordsPool.filter((w) => !usedWordIds.includes(w.id));

      if (unusedWords.length === 0) {
        await gameRef.update({
          status: 'finished',
          isWin: true,
          terminationReason: 'completed_all_words',
          score: newScore,
          validatedScore: newScore,
          lastWordPoints: wordPoints,
          wordsCompleted: newWordsCompleted,
          averageSpeed,
          accuracy,
          wordsLog,
          usedWordIds,
          wordDeadlineAt: null,
          wordDeadlineAtMs: null,
          validated: true,
          finishedAtMs: nowMs,
          finishedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await promoteScoreToRankingIfEligible(
          db,
          {
            ...game,
            wordsCompleted: newWordsCompleted,
            averageSpeed,
            accuracy,
          },
          newScore
        );

        return res.status(200).json({
          gameId,
          status: 'finished',
          isWin: true,
          expired: false,
          score: newScore,
          lastWordPoints: wordPoints,
          wordsCompleted: newWordsCompleted,
          pauseCount: Number(game.pauseCount || 0),
          remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
          averageSpeed,
          actualDurationMs,
        });
      }

      const nextWord = unusedWords[Math.floor(Math.random() * unusedWords.length)];
      usedWordIds.push(nextWord.id);
      const nextSequence = Number(game.wordSequence || 1) + 1;
      const allowedTimeMs = getAllowedWordTimeMs(nextWord.text);
      const nextDeadlineAtMs = nowMs + allowedTimeMs;
      const wordStartedAtIso = new Date(nowMs).toISOString();
      const nextDeadlineAtIso = new Date(nextDeadlineAtMs).toISOString();

      await gameRef.update({
        status: 'running',
        currentWord: nextWord,
        usedWordIds,
        wordSequence: nextSequence,
        wordStartedAt: wordStartedAtIso,
        wordStartedAtMs: nowMs,
        wordDeadlineAt: nextDeadlineAtIso,
        wordDeadlineAtMs: nextDeadlineAtMs,
        remainingWordTimeMs: allowedTimeMs,
        currentWordPausedMs: 0,
        score: newScore,
        validatedScore: newScore,
        lastWordPoints: wordPoints,
        wordsCompleted: newWordsCompleted,
        totalWordsPool: wordsPool.length,
        averageSpeed,
        accuracy,
        wordsLog,
        validated: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      scheduleServerWordTimeout({
        db,
        gameId,
        wordSequence: nextSequence,
        delayMs: allowedTimeMs,
      });

      return res.status(200).json({
        gameId,
        status: 'running',
        isWin: false,
        expired: false,
        currentWord: nextWord,
        wordSequence: nextSequence,
        totalWordsPool: wordsPool.length,
        allowedTimeMs,
        remainingTimeMs: allowedTimeMs,
        serverNowMs: nowMs,
        wordStartedAt: wordStartedAtIso,
        wordStartedAtMs: nowMs,
        wordDeadlineAt: nextDeadlineAtIso,
        wordDeadlineAtMs: nextDeadlineAtMs,
        score: newScore,
        lastWordPoints: wordPoints,
        wordsCompleted: newWordsCompleted,
        pauseCount: Number(game.pauseCount || 0),
        remainingPauses: Math.max(0, MAX_PAUSES - Number(game.pauseCount || 0)),
        averageSpeed,
        actualDurationMs,
      });
    }

    return res.status(400).json({ error: `Unsupported action: ${action}` });
  } catch (error) {
    return res.status(500).json({
      error: 'Game session action failed',
      details: error.message,
    });
  }
}

handler.expireGameIfDeadlinePassed = expireGameIfDeadlinePassed;
handler.scheduleServerWordTimeout = scheduleServerWordTimeout;
handler.getAllowedWordTimeMs = getAllowedWordTimeMs;
handler.calculateWordPoints = calculateWordPoints;

module.exports = handler;
