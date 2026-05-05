/**
 * translate_product_names.js
 *
 * Rellena nameEn y nameFr en todos los productos de Firestore que no los tengan,
 * usando Google Cloud Translation API v2.
 *
 * REQUISITOS:
 *   1. Tener habilitada "Cloud Translation API" en tu proyecto de Google Cloud.
 *   2. Crear una API Key en console.cloud.google.com → APIs & Services → Credentials.
 *   3. Exportar la clave: set GOOGLE_TRANSLATE_KEY=AIza...
 *
 * USO:
 *   set GOOGLE_TRANSLATE_KEY=AIza...
 *   node scripts/translate_product_names.js
 *
 * COSTO REFERENCIAL:
 *   $20 USD por 1,000,000 caracteres.
 *   500 nombres de productos × ~25 chars × 2 idiomas ≈ 25,000 chars ≈ $0.50 USD
 */

const admin = require('firebase-admin');
const https  = require('https');

// ── Inicializar Firebase Admin ────────────────────────────────────────────────
const serviceAccount = require('../serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const API_KEY = process.env.GOOGLE_TRANSLATE_KEY;
if (!API_KEY) {
  console.error('❌ Falta la variable GOOGLE_TRANSLATE_KEY.');
  console.error('   Ejemplo: set GOOGLE_TRANSLATE_KEY=AIza... && node scripts/translate_product_names.js');
  process.exit(1);
}

// ── Función de traducción ─────────────────────────────────────────────────────
function translate(text, targetLang) {
  return new Promise((resolve, reject) => {
    if (!text || !text.trim()) return resolve('');

    const body = JSON.stringify({ q: text, source: 'es', target: targetLang, format: 'text' });
    const options = {
      hostname: 'translation.googleapis.com',
      path: `/language/translate/v2?key=${API_KEY}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          const translated = json?.data?.translations?.[0]?.translatedText;
          if (!translated) return reject(new Error(`Sin traducción para "${text}": ${data}`));
          resolve(translated);
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log('📦 Leyendo productos de Firestore...');
  const snap = await db.collection('products').get();
  console.log(`   ${snap.size} productos encontrados.\n`);

  let updated = 0;
  let skipped = 0;
  let errors  = 0;

  for (const doc of snap.docs) {
    const data  = doc.data();
    const name  = (data.name || data.nombre || '').trim();

    const needsEn = !data.nameEn || data.nameEn.trim() === '';
    const needsFr = !data.nameFr || data.nameFr.trim() === '';

    if (!needsEn && !needsFr) { skipped++; continue; }
    if (!name)                { skipped++; continue; }

    process.stdout.write(`  🌐 "${name}" → `);

    try {
      const update = {};

      if (needsEn) {
        update.nameEn = await translate(name, 'en');
        process.stdout.write(`EN:"${update.nameEn}"  `);
        await sleep(100); // evitar rate-limit
      }
      if (needsFr) {
        update.nameFr = await translate(name, 'fr');
        process.stdout.write(`FR:"${update.nameFr}"`);
        await sleep(100);
      }

      await db.collection('products').doc(doc.id).update(update);
      console.log('  ✅');
      updated++;
    } catch (err) {
      console.log(`  ❌ ${err.message}`);
      errors++;
    }
  }

  console.log(`\n✔  Listo.`);
  console.log(`   Actualizados : ${updated}`);
  console.log(`   Ya traducidos: ${skipped}`);
  console.log(`   Errores      : ${errors}`);
  process.exit(0);
}

main().catch((err) => { console.error(err); process.exit(1); });
