import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

async function seedLanguage(apiBaseUrl, adminToken, language, relativeJsonPath) {
  const fullPath = path.join(rootDir, relativeJsonPath);
  const raw = await fs.readFile(fullPath, 'utf8');
  const words = JSON.parse(raw);

  const endpoint = `${apiBaseUrl.replace(/\/$/, '')}/api/register-words`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${adminToken}`,
    },
    body: JSON.stringify({
      language,
      words,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(
      `Failed seeding ${language} (${response.status}): ${JSON.stringify(payload)}`
    );
  }
  console.log(`[seed_words] Registered ${payload.registeredCount} words for "${language}"`);
}

async function main() {
  const apiBaseUrl = process.env.API_BASE_URL;
  const adminToken = process.env.ADMIN_SEED_TOKEN;

  if (!apiBaseUrl || !adminToken) {
    console.error(
      'Missing API_BASE_URL or ADMIN_SEED_TOKEN environment variables.'
    );
    process.exit(1);
  }

  await seedLanguage(apiBaseUrl, adminToken, 'pt', 'assets/words/pt.json');
  await seedLanguage(apiBaseUrl, adminToken, 'en', 'assets/words/en.json');
}

main().catch((err) => {
  console.error('[seed_words] Error:', err.message);
  process.exit(1);
});
