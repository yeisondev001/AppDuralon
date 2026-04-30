/**
 * Cambia imageUrl en Firestore de:
 *   https://storage.googleapis.com/...           (sin CORS)
 * a:
 *   https://firebasestorage.googleapis.com/v0/b/...?alt=media&token=...  (CORS OK)
 *
 * Lee el token desde los metadatos que guardó upload-product-images.js.
 * Uso: node fix-urls-to-firebase.js
 */

const admin = require('firebase-admin');
const fs    = require('fs');
const path  = require('path');

const KEY_PATH    = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
const BUCKET_NAME = 'appduralon.firebasestorage.app';

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
  storageBucket: BUCKET_NAME,
});

const bucket = admin.storage().bucket();
const db     = admin.firestore();

function firebaseUrl(storagePath, token) {
  const encoded = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/${encoded}?alt=media&token=${token}`;
}

function parseStoragePath(filePath) {
  const name = path.parse(filePath).name;
  const match = name.match(/^(.+?)_(\d+)$/);
  return match
    ? { id: match[1], isMain: false }
    : { id: name,     isMain: true  };
}

async function main() {
  const [files] = await bucket.getFiles({ prefix: 'products/' });
  const imageFiles = files.filter(f => /\.(jpg|jpeg|png)$/i.test(f.name));

  console.log(`\nLeyendo tokens de ${imageFiles.length} imágenes...\n`);

  const urlMap = {};

  for (let i = 0; i < imageFiles.length; i++) {
    const file = imageFiles[i];
    const [meta] = await file.getMetadata();
    const token  = meta.metadata?.firebaseStorageDownloadTokens;

    if (!token) {
      console.log(`  [SIN TOKEN] ${file.name} — omitido`);
      continue;
    }

    const url = firebaseUrl(file.name, token);
    const { id, isMain } = parseStoragePath(file.name);

    if (!urlMap[id]) urlMap[id] = { main: null, extra: [] };
    if (isMain) urlMap[id].main = url;
    else        urlMap[id].extra.push(url);

    process.stdout.write(`\r  [${i + 1}/${imageFiles.length}] ${file.name.padEnd(40)}`);
  }

  console.log('\n\nActualizando Firestore...\n');

  let updated = 0, skipped = 0;

  for (const [productId, { main, extra }] of Object.entries(urlMap)) {
    const ref  = db.collection('products').doc(productId);
    const snap = await ref.get();
    if (!snap.exists) { skipped++; continue; }

    const update = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (main)         update.imageUrl  = main;
    if (extra.length) update.imageUrls = extra;

    await ref.update(update);
    updated++;
    console.log(`  [OK] ${productId}`);
  }

  console.log(`\n────────────────────────────────────`);
  console.log(`Productos actualizados : ${updated}`);
  console.log(`Sin doc en Firestore   : ${skipped}`);
  console.log('────────────────────────────────────\n');
}

main().catch(err => { console.error('Error:', err.message); process.exit(1); });
