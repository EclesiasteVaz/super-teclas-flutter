const admin = require('firebase-admin');

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

module.exports = async function handler(req, res) {
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
    const gameId = String(body.gameId || '').trim();
    if (!gameId) {
      return res.status(400).json({ error: 'gameId is required' });
    }

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

    const gameRef = db.collection('games').doc(gameId);
    const gameSnap = await gameRef.get();

    if (!gameSnap.exists) {
      return res.status(404).json({ error: 'Game session not found' });
    }

    const game = gameSnap.data();

    if (game.userId && game.userId !== verifiedUid) {
      return res.status(403).json({
        valid: false,
        reason: 'Game userId does not match authenticated user',
      });
    }

    const resolvedUsername = String(body.username || game.username || '').trim();
    const resolvedSessionId = String(body.sessionId || game.sessionId || game.userId || verifiedUid || 'anonymous').trim();
    const resolvedAccuracy =
      body.accuracy !== undefined
        ? Number(body.accuracy)
        : Number(game.accuracy ?? 100);

    const canUpdateRanking = (existingData) => {
      if (!existingData) return true;
      const existingSessionId = String(existingData.sessionId || '').trim();
      if (existingSessionId && resolvedSessionId && resolvedSessionId !== 'anonymous') {
        return existingSessionId === resolvedSessionId;
      }
      const existingUserId = String(existingData.userId || '').trim();
      const gameUserId = String(game.userId || verifiedUid || '').trim();
      if (
        existingUserId &&
        existingUserId !== 'anonymous' &&
        gameUserId &&
        gameUserId !== 'anonymous'
      ) {
        return existingUserId === gameUserId;
      }
      return true;
    };

    if (game.validated === true) {
      const existingScore = Number(game.validatedScore ?? game.score ?? 0);
      const validAccuracy =
        !Number.isNaN(resolvedAccuracy) &&
        resolvedAccuracy >= 0 &&
        resolvedAccuracy <= 100
          ? resolvedAccuracy
          : Number(game.accuracy ?? 100);

      if (resolvedUsername || body.accuracy !== undefined) {
        await gameRef.update({
          ...(resolvedUsername
            ? {
                username: resolvedUsername,
                usernameLower: resolvedUsername.toLowerCase(),
              }
            : {}),
          sessionId: resolvedSessionId,
          accuracy: validAccuracy,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      if (resolvedUsername && existingScore > 0) {
        const rankingId = resolvedUsername.toLowerCase();
        const rankingRef = db.collection('rankings').doc(rankingId);
        const existingSnap = await rankingRef.get();
        const existingData = existingSnap.exists ? existingSnap.data() : null;
        if (
          canUpdateRanking(existingData) &&
          (!existingSnap.exists ||
            Number(existingData.score || 0) < existingScore ||
            existingData.gameId === gameId)
        ) {
          await rankingRef.set(
            {
              sessionId: resolvedSessionId,
              userId: game.userId || verifiedUid || 'anonymous',
              username: resolvedUsername,
              usernameLower: rankingId,
              score: existingScore,
              words_completed: Number(game.wordsCompleted || 0),
              accuracy: validAccuracy,
              average_speed: Number(game.averageSpeed || 0),
              gameId,
              created_at:
                existingData && existingData.gameId === gameId && existingData.created_at
                  ? existingData.created_at
                  : new Date().toISOString(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      }
      return res.status(200).json({
        valid: true,
        alreadyValidated: true,
        score: existingScore,
      });
    }

    const rejectGame = async (reason) => {
      await gameRef.update({
        status: 'rejected',
        validated: false,
        rejectionReason: reason,
        validatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return res.status(422).json({
        valid: false,
        reason,
      });
    };

    if (game.status === 'running') {
      game.status = 'finished';
      await gameRef.update({
        status: 'finished',
        sessionId: resolvedSessionId,
        username: resolvedUsername || game.username || '',
        usernameLower: (resolvedUsername || game.username || '').toLowerCase(),
        accuracy: Number.isNaN(resolvedAccuracy) ? 100 : resolvedAccuracy,
        wordDeadlineAt: null,
        wordDeadlineAtMs: null,
        finishedAtMs: Date.now(),
        finishedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (game.status !== 'finished') {
      return await rejectGame('Game status must be finished before validation');
    }

    const pauseCount = Number(game.pauseCount || 0);
    if (pauseCount < 0 || pauseCount > 3) {
      return await rejectGame('Maximum allowed pauses (3) exceeded');
    }

    const wordsLog = Array.isArray(game.wordsLog) ? game.wordsLog : [];
    const wordsCompleted = Number(game.wordsCompleted || 0);

    if (wordsCompleted !== wordsLog.length) {
      return await rejectGame('wordsCompleted does not match wordsLog length');
    }

    const accuracy = resolvedAccuracy;
    if (Number.isNaN(accuracy) || accuracy < 0 || accuracy > 100) {
      return await rejectGame('Invalid accuracy value');
    }

    const seenWords = new Set();
    let recalculatedScore = 0;
    let sumActualDurationMs = 0;

    for (const entry of wordsLog) {
      if (!entry || typeof entry !== 'object') {
        return await rejectGame('Invalid entry in wordsLog');
      }

      const wordText = String(entry.wordText || '').trim();
      if (!wordText) {
        return await rejectGame('Empty wordText in wordsLog');
      }

      const key = wordText.toLowerCase();
      if (seenWords.has(key)) {
        return await rejectGame(`Duplicate word detected in session: ${wordText}`);
      }
      seenWords.add(key);

      if (entry.stateWhenTyped !== 'running') {
        return await rejectGame('Word registered while game was not in running state');
      }

      const actualDurationMs = Number(entry.actualDurationMs || 0);
      const minHumanDurationMs = wordText.length * 40;
      if (actualDurationMs < minHumanDurationMs) {
        return await rejectGame(
          `Biomechanical speed limit violated for word "${wordText}" (${actualDurationMs}ms < ${minHumanDurationMs}ms)`
        );
      }

      const difficulty = String(entry.difficulty || 'medium').toLowerCase();
      const expectedDurationMs =
        Number(entry.expectedDurationMs) > 0
          ? Number(entry.expectedDurationMs)
          : calculateExpectedDurationMs(wordText, difficulty);

      recalculatedScore += calculateWordPoints(
        difficulty,
        expectedDurationMs,
        actualDurationMs
      );
      sumActualDurationMs += actualDurationMs;
    }

    const totalPausedDurationMs = Math.max(0, Number(game.totalPausedDurationMs || 0));
    if (game.startedAt && game.finishedAt) {
      const startMs = game.startedAt.toMillis
        ? game.startedAt.toMillis()
        : Date.parse(game.startedAt);
      const finishMs = game.finishedAt.toMillis
        ? game.finishedAt.toMillis()
        : Date.parse(game.finishedAt);

      if (!Number.isNaN(startMs) && !Number.isNaN(finishMs)) {
        const sessionDurationMs = finishMs - startMs;
        if (sessionDurationMs + 1500 < sumActualDurationMs + totalPausedDurationMs) {
          return await rejectGame('Session duration is shorter than sum of word and pause times');
        }
      }
    }

    const averageSpeed =
      wordsLog.length > 0
        ? Number((sumActualDurationMs / wordsLog.length / 1000).toFixed(2))
        : 0;

    await gameRef.update({
      sessionId: resolvedSessionId,
      username: resolvedUsername,
      usernameLower: resolvedUsername.toLowerCase(),
      accuracy,
      validated: true,
      validatedScore: recalculatedScore,
      averageSpeed,
      validatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const username = resolvedUsername;
    if (username && recalculatedScore > 0) {
      const rankingId = username.toLowerCase();
      const rankingRef = db.collection('rankings').doc(rankingId);
      const existingSnap = await rankingRef.get();
      const existingData = existingSnap.exists ? existingSnap.data() : null;

      if (
        canUpdateRanking(existingData) &&
        (!existingSnap.exists || Number(existingData.score || 0) < recalculatedScore)
      ) {
        await rankingRef.set(
          {
            sessionId: resolvedSessionId,
            userId: game.userId || verifiedUid || 'anonymous',
            username,
            usernameLower: rankingId,
            score: recalculatedScore,
            words_completed: wordsCompleted,
            accuracy,
            average_speed: averageSpeed,
            gameId,
            created_at: new Date().toISOString(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }

    return res.status(200).json({
      valid: true,
      score: recalculatedScore,
      wordsCompleted,
      averageSpeed,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Validation failed',
      details: error.message,
    });
  }
};
