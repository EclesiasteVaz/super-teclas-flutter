import dns from 'node:dns';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

dns.setDefaultResultOrder('ipv4first');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

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

function normalizeWords(rawWords, language) {
  const byId = new Map();
  for (const item of rawWords) {
    const text = String(item.word || item.text || '').trim();
    if (!text) continue;
    const rawDiff = String(item.difficulty || '').toLowerCase();
    const difficulty = ['easy', 'medium', 'hard'].includes(rawDiff)
      ? rawDiff
      : 'medium';
    const definition = String(item.definition || '').trim();
    const expectedDurationMs =
      typeof item.expectedDurationMs === 'number' && item.expectedDurationMs > 0
        ? item.expectedDurationMs
        : calculateExpectedDurationMs(text, difficulty);
    const id = sanitizeDocId(language, text);
    byId.set(id, {
      id,
      word: text,
      text,
      difficulty,
      definition,
      language,
      length: text.length,
      expectedDurationMs,
    });
  }
  return Array.from(byId.values());
}

async function getAuthBearerHeader(apiKey) {
  try {
    const homeDir = process.env.HOME || process.env.USERPROFILE || '';
    if (homeDir) {
      const cfgPath = path.join(homeDir, '.config', 'configstore', 'firebase-tools.json');
      const rawCfg = await fs.readFile(cfgPath, 'utf8');
      const parsedCfg = JSON.parse(rawCfg);
      const accessToken = parsedCfg?.tokens?.access_token;
      const expiresAt = Number(parsedCfg?.tokens?.expires_at || 0);
      if (accessToken && (!expiresAt || expiresAt > Date.now() + 30000)) {
        return { Authorization: `Bearer ${accessToken}` };
      }
    }
  } catch (_) {}

  if (!apiKey) return {};
  try {
    const res = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ returnSecureToken: true }),
      }
    );
    if (res.ok) {
      const data = await res.json();
      if (data.idToken) {
        return { Authorization: `Bearer ${data.idToken}` };
      }
    }
  } catch (_) {}
  return {};
}

async function seedViaFirestoreRest(projectId, apiKey, language, validWords) {
  const commitUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;
  const authHeader = await getAuthBearerHeader(apiKey);
  const chunkSize = 200;
  let registeredCount = 0;
  const nowIso = new Date().toISOString();

  for (let i = 0; i < validWords.length; i += chunkSize) {
    const chunk = validWords.slice(i, i + chunkSize);
    const writes = chunk.map((wordObj) => ({
      update: {
        name: `projects/${projectId}/databases/(default)/documents/words/${wordObj.id}`,
        fields: {
          id: { stringValue: wordObj.id },
          word: { stringValue: wordObj.text },
          text: { stringValue: wordObj.text },
          difficulty: { stringValue: wordObj.difficulty },
          definition: { stringValue: wordObj.definition },
          language: { stringValue: wordObj.language },
          length: { integerValue: String(wordObj.length) },
          expectedDurationMs: { integerValue: String(wordObj.expectedDurationMs) },
          updatedAt: { timestampValue: nowIso },
        },
      },
    }));

    const response = await fetch(commitUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...authHeader,
      },
      body: JSON.stringify({ writes }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(
        `Firestore REST commit failed for ${language} (${response.status}): ${errorText}`
      );
    }

    registeredCount += chunk.length;
  }

  console.log(
    `[seed_words] Registered ${registeredCount} words for "${language}" in Firestore (${projectId})`
  );
}

async function seedLanguage({
  apiBaseUrl,
  adminToken,
  projectId,
  apiKey,
  language,
  relativeJsonPath,
}) {
  const fullPath = path.join(rootDir, relativeJsonPath);
  const raw = await fs.readFile(fullPath, 'utf8');
  const rawWords = JSON.parse(raw);
  const validWords = normalizeWords(rawWords, language);

  const isPlaceholderUrl =
    !apiBaseUrl ||
    apiBaseUrl.includes('your-project.vercel.app') ||
    apiBaseUrl.trim() === '';

  if (!isPlaceholderUrl && adminToken) {
    try {
      const endpoint = `${apiBaseUrl.replace(/\/$/, '')}/api/register-words`;
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
        body: JSON.stringify({
          language,
          words: validWords,
        }),
      });

      if (response.ok) {
        const payload = await response.json();
        console.log(
          `[seed_words] Registered ${payload.registeredCount} words for "${language}" via ${endpoint}`
        );
        return;
      }
      const errBody = await response.text();
      console.warn(
        `[seed_words] Endpoint ${endpoint} returned ${response.status} (${errBody.slice(0, 120)}). Falling back to direct Firestore seeding...`
      );
    } catch (err) {
      console.warn(
        `[seed_words] Endpoint unreachable (${err.message}). Falling back to direct Firestore seeding...`
      );
    }
  }

  await seedViaFirestoreRest(projectId, apiKey, language, validWords);
}

async function loadDotEnv() {
  try {
    const envPath = path.join(rootDir, '.env');
    const content = await fs.readFile(envPath, 'utf8');
    for (const line of content.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx === -1) continue;
      const key = trimmed.slice(0, eqIdx).trim();
      const val = trimmed.slice(eqIdx + 1).trim();
      if (!process.env[key]) {
        process.env[key] = val;
      }
    }
  } catch (_) {}
}

async function main() {
  await loadDotEnv();
  const apiBaseUrl = process.env.API_BASE_URL || '';
  const adminToken = process.env.ADMIN_SEED_TOKEN || '';
  const projectId = process.env.FIREBASE_PROJECT_ID || '';
  const apiKey = process.env.FIREBASE_API_KEY || '';

  if (!projectId && !apiBaseUrl) {
    throw new Error('Missing FIREBASE_PROJECT_ID or API_BASE_URL in .env or environment.');
  }

  await seedLanguage({
    apiBaseUrl,
    adminToken,
    projectId,
    apiKey,
    language: 'pt',
    relativeJsonPath: 'scripts/words/pt.json',
  });
  await seedLanguage({
    apiBaseUrl,
    adminToken,
    projectId,
    apiKey,
    language: 'en',
    relativeJsonPath: 'scripts/words/en.json',
  });
}

main().catch((err) => {
  console.error('[seed_words] Error:', err.message);
  process.exit(1);
});
