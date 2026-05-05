/**
 * Borra todos los documentos en `products/` que NO tienen ningún campo.
 * (Documentos creados sin datos — basura.)
 *
 * Uso: node limpiar-productos-vacios.js
 */
const admin = require('firebase-admin');
const fs    = require('fs');

const KEY_PATH = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
});

const db = admin.firestore();

async function main() {
  const snap = await db.collection('products').get();

  const emptyDocs = snap.docs.filter(d => Object.keys(d.data()).length === 0);
  console.log(`Total documentos: ${snap.size}`);
  console.log(`Documentos vacíos a borrar: ${emptyDocs.length}`);

  if (emptyDocs.length === 0) {
    console.log('Nada que borrar. Saliendo.');
    process.exit(0);
  }

  // Borrado en lotes de 400 (límite batch = 500)
  const BATCH = 400;
  let deleted = 0;
  for (let i = 0; i < emptyDocs.length; i += BATCH) {
    const slice = emptyDocs.slice(i, i + BATCH);
    const batch = db.batch();
    slice.forEach(d => batch.delete(d.ref));
    await batch.commit();
    deleted += slice.length;
    console.log(`  Borrados ${deleted}/${emptyDocs.length}`);
  }

  console.log(`\n✓ Listo. Eliminados ${deleted} documentos vacíos.`);
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
