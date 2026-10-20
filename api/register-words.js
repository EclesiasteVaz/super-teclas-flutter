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

function sanitizeDocId(language, text) {
  const normalized = String(text || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\u00C0-\u017F_-]/gi, '_');
  return `${language}_${normalized}`;
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

  const expectedToken = process.env.ADMIN_SEED_TOKEN;
  const authHeader = req.headers.authorization || '';
  const providedToken = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7).trim()
    : '';

  if (!expectedToken || providedToken !== expectedToken) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    initFirebaseAdmin();
    const db = admin.firestore();

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const language = body.language === 'en' ? 'en' : 'pt';
    const rawWords = Array.isArray(body.words) ? body.words : [];

    if (rawWords.length === 0) {
      return res.status(400).json({ error: 'Words array is required and cannot be empty' });
    }

    const validWords = [];
    for (const item of rawWords) {
      const text = String(item.word || item.text || '').trim();
      if (!text) continue;
      const difficulty = ['easy', 'medium', 'hard'].includes(
        String(item.difficulty || '').toLowerCase()
      )
        ? String(item.difficulty).toLowerCase()
        : 'medium';
      const definition = String(item.definition || '').trim();
      const expectedDurationMs =
        typeof item.expectedDurationMs === 'number' && item.expectedDurationMs > 0
          ? item.expectedDurationMs
          : calculateExpectedDurationMs(text, difficulty);

      validWords.push({
        id: sanitizeDocId(language, text),
        text,
        difficulty,
        definition,
        language,
        length: text.length,
        expectedDurationMs,
      });
    }

    const chunkSize = 450;
    let registeredCount = 0;

    for (let i = 0; i < validWords.length; i += chunkSize) {
      const chunk = validWords.slice(i, i + chunkSize);
      const batch = db.batch();
      for (const wordObj of chunk) {
        const ref = db.collection('words').doc(wordObj.id);
        batch.set(
          ref,
          {
            text: wordObj.text,
            difficulty: wordObj.difficulty,
            definition: wordObj.definition,
            language: wordObj.language,
            length: wordObj.length,
            expectedDurationMs: wordObj.expectedDurationMs,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        registeredCount++;
      }
      await batch.commit();
    }

    return res.status(200).json({
      success: true,
      language,
      registeredCount,
    });
  } catch (error) {
    return res.status(500).json({
      error: 'Failed to register words',
      details: error.message,
    });
  }
};
