/**
 * Configura CORS en el bucket de Firebase Storage para permitir
 * que Flutter Web cargue imágenes desde el navegador.
 * Uso: node set-storage-cors.js
 */

const admin = require('firebase-admin');
const fs    = require('fs');

const KEY_PATH    = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
const BUCKET_NAME = 'appduralon.firebasestorage.app';

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
  storageBucket: BUCKET_NAME,
});

async function main() {
  const bucket = admin.storage().bucket();

  await bucket.setCorsConfiguration([
    {
      origin: ['*'],
      method: ['GET', 'HEAD'],
      responseHeader: ['Content-Type', 'Content-Length', 'Cache-Control'],
      maxAgeSeconds: 3600,
    },
  ]);

  console.log('✓ CORS configurado en', BUCKET_NAME);

  // Verificar que quedó aplicado
  const [metadata] = await bucket.getMetadata();
  console.log('CORS activo:', JSON.stringify(metadata.cors, null, 2));
}

main().catch(err => { console.error('Error:', err.message); process.exit(1); });
