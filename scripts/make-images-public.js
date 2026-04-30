/**
 * Hace públicas todas las imágenes en products/ y actualiza imageUrl en Firestore
 * con la URL pública estática (sin token, sin %2F).
 *
 * URL resultante: https://storage.googleapis.com/{bucket}/products/BANIDA.jpg
 *
 * Uso: node make-images-public.js
 */

const admin = require('firebase-admin');
const fs    = require('fs');

const KEY_PATH    = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
const BUCKET_NAME = 'appduralon.firebasestorage.app';

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
  storageBucket: BUCKET_NAME,
});

const bucket = admin.storage().bucket();
const db     = admin.firestore();

function publicUrl(filePath) {
  return `https://storage.googleapis.com/${BUCKET_NAME}/${filePath}`;
}

async function main() {
  // Listar todos los archivos en products/
  const [files] = await bucket.getFiles({ prefix: 'products/' });
  const imageFiles = files.filter(f => /\.(jpg|jpeg|png)$/i.test(f.name));

  console.log(`\nHaciendo públicas ${imageFiles.length} imágenes...\n`);

  // Agrupa por productId igual que antes
  // products/E3605.jpg   → { id: 'E3605', isMain: true  }
  // products/E3605_2.jpg → { id: 'E3605', isMain: false }
  const path = require('path');
  function parseStoragePath(filePath) {
    const name = path.parse(filePath).name;
    const match = name.match(/^(.+?)_(\d+)$/);
    return match
      ? { id: match[1], isMain: false }
      : { id: name,    isMain: true  };
  }

  const urlMap = {};

  for (let i = 0; i < imageFiles.length; i++) {
    const file = imageFiles[i];
    process.stdout.write(`[${i + 1}/${imageFiles.length}] ${file.name} → public... `);
    try {
      await file.makePublic();
      const url = publicUrl(file.name);
      const { id, isMain } = parseStoragePath(file.name);

      if (!urlMap[id]) urlMap[id] = { main: null, extra: [] };
      if (isMain) urlMap[id].main = url;
      else        urlMap[id].extra.push(url);

      console.log('✓');
    } catch (err) {
      console.log(`✗ ${err.message}`);
    }
  }

  // Actualizar Firestore
  console.log('\nActualizando imageUrl en Firestore...\n');
  let updated = 0, skipped = 0;

  for (const [productId, { main, extra }] of Object.entries(urlMap)) {
    const ref  = db.collection('products').doc(productId);
    const snap = await ref.get();
    if (!snap.exists) { skipped++; continue; }

    const update = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (main)         update.imageUrl  = main;
    if (extra.length) update.imageUrls = extra;

    await ref.update(update);
    console.log(`  [OK] ${productId}${main ? ' → ' + main.split('/').pop() : ''}`);
    updated++;
  }

  console.log(`\n────────────────────────────────────`);
  console.log(`Imágenes públicas  : ${imageFiles.length}`);
  console.log(`Firestore updated  : ${updated}`);
  console.log(`Sin doc en Firestore: ${skipped}`);
  console.log('────────────────────────────────────\n');
}

main().catch(err => { console.error('Error fatal:', err); process.exit(1); });
