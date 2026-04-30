/**
 * Sube todas las imágenes de productos a Firebase Storage y actualiza
 * el campo imageUrl (y imageUrls[]) en cada documento de Firestore.
 *
 * Regla de nombres:
 *   E3600.jpg   → imageUrl principal del producto "E3600"
 *   E3605_2.jpg → se agrega a imageUrls[] del producto "E3605"
 *
 * Uso: node upload-product-images.js
 */

const admin = require('firebase-admin');
const fs    = require('fs');
const path  = require('path');
const crypto = require('crypto');

// ── Configuración ────────────────────────────────────────────────────────────

const KEY_PATH    = 'C:\\Users\\Usuarios\\AppData\\Local\\firebase-keys\\appduralon.json';
const IMAGES_DIR  = 'C:\\Users\\Usuarios\\Desktop\\plantillasappDuralon\\fotos codigos';
const BUCKET_NAME = 'appduralon.firebasestorage.app';
const STORAGE_DIR = 'products'; // carpeta dentro del bucket

// ── Init ─────────────────────────────────────────────────────────────────────

const serviceAccount = JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: BUCKET_NAME,
});

const bucket = admin.storage().bucket();
const db     = admin.firestore();

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Sube un archivo y devuelve la URL permanente de descarga (Firebase-style).
 * La URL usa el token UUID que se guarda en los metadatos del objeto.
 */
async function uploadFile(localPath, destPath) {
  const token = crypto.randomUUID();
  await bucket.upload(localPath, {
    destination: destPath,
    metadata: {
      contentType: localPath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  const encoded = encodeURIComponent(destPath);
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET_NAME}/o/${encoded}?alt=media&token=${token}`;
}

/**
 * Extrae el productId y si es imagen principal o adicional.
 * "E3605.jpg"   → { id: 'E3605',   isMain: true  }
 * "E3605_2.jpg" → { id: 'E3605',   isMain: false }
 * "CUBER_2.jpg" → { id: 'CUBER',   isMain: false }
 */
function parseFilename(filename) {
  const name = path.parse(filename).name; // sin extensión
  const match = name.match(/^(.+?)_(\d+)$/);
  if (match) {
    return { id: match[1], isMain: false };
  }
  return { id: name, isMain: true };
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const files = fs.readdirSync(IMAGES_DIR).filter(f =>
    /\.(jpg|jpeg|png)$/i.test(f)
  );

  console.log(`\nEncontradas ${files.length} imágenes. Iniciando subida...\n`);

  // Agrupa por productId: { E3605: { main: 'url', extra: ['url2','url3'] } }
  const urlMap = {};

  for (let i = 0; i < files.length; i++) {
    const file    = files[i];
    const { id, isMain } = parseFilename(file);
    const localPath = path.join(IMAGES_DIR, file);
    const destPath  = `${STORAGE_DIR}/${file}`;

    process.stdout.write(`[${i + 1}/${files.length}] ${file} → Storage... `);

    try {
      const url = await uploadFile(localPath, destPath);

      if (!urlMap[id]) urlMap[id] = { main: null, extra: [] };

      if (isMain) {
        urlMap[id].main = url;
      } else {
        urlMap[id].extra.push(url);
      }

      console.log('✓');
    } catch (err) {
      console.log(`✗ Error: ${err.message}`);
    }
  }

  // ── Actualizar Firestore ──────────────────────────────────────────────────
  console.log('\nActualizando documentos en Firestore...\n');

  const ids = Object.keys(urlMap);
  let updated = 0, notFound = 0;

  for (const productId of ids) {
    const { main, extra } = urlMap[productId];
    const ref = db.collection('products').doc(productId);
    const snap = await ref.get();

    if (!snap.exists) {
      console.log(`  [NO EXISTE] products/${productId}`);
      notFound++;
      continue;
    }

    const update = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };

    if (main) update.imageUrl = main;

    if (extra.length > 0) {
      update.imageUrls = admin.firestore.FieldValue.arrayUnion(...extra);
    }

    await ref.update(update);
    console.log(`  [OK] products/${productId}${main ? ' → imageUrl' : ''}${extra.length ? ` + ${extra.length} extra` : ''}`);
    updated++;
  }

  console.log(`\n─────────────────────────────────────`);
  console.log(`Imágenes subidas : ${files.length}`);
  console.log(`Productos actualizados : ${updated}`);
  console.log(`Docs no encontrados   : ${notFound}`);
  console.log('─────────────────────────────────────\n');
}

main().catch(err => {
  console.error('\nError fatal:', err);
  process.exit(1);
});
