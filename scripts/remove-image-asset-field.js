/**
 * Elimina el campo `imageAsset` de todos los documentos en la colección `products`.
 * Uso: node remove-image-asset-field.js
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
  if (snap.empty) { console.log('No hay documentos.'); return; }

  console.log(`\nEliminando imageAsset de ${snap.docs.length} documentos...\n`);

  const SIZE = 400;
  let removed = 0;

  for (let i = 0; i < snap.docs.length; i += SIZE) {
    const batch = db.batch();
    const chunk = snap.docs.slice(i, i + SIZE);
    for (const doc of chunk) {
      if (doc.data().imageAsset !== undefined) {
        batch.update(doc.ref, {
          imageAsset: admin.firestore.FieldValue.delete(),
          updatedAt:  admin.firestore.FieldValue.serverTimestamp(),
        });
        removed++;
      }
    }
    await batch.commit();
  }

  console.log(`✓ imageAsset eliminado de ${removed} documentos.`);
}

main().catch(err => { console.error('Error:', err); process.exit(1); });
