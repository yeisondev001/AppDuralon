// Script de una sola vez:
//  1. Renombra el campo `price` → `precio` en TODOS los docs de la colección `products`
//  2. Asigna un valor aleatorio (RD$ 50–2500, múltiplo de 5) al nuevo campo
//  3. Borra el campo `price` viejo
//
// Uso (desde la raíz del worktree):
//   cd scripts
//   npm install firebase-admin
//   set GOOGLE_APPLICATION_CREDENTIALS=C:\Users\Usuarios\Desktop\fb-key.json   (Windows CMD)
//   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\Usuarios\Desktop\fb-key.json" (PowerShell)
//   node rename-price-to-precio.js

const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'appduralon',
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const MIN_PRICE = 50;
const MAX_PRICE = 2500;
const BATCH_SIZE = 400; // límite de Firestore es 500

function randomPrice() {
  const raw = MIN_PRICE + Math.floor(Math.random() * (MAX_PRICE - MIN_PRICE + 1));
  return Math.round(raw / 5) * 5;
}

async function main() {
  console.log('Leyendo colección `products`…');
  const snap = await db.collection('products').get();
  const docs = snap.docs;
  console.log(`  → ${docs.length} productos encontrados.`);

  if (docs.length === 0) {
    console.log('Nada que actualizar.');
    return;
  }

  let done = 0;
  for (let i = 0; i < docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const slice = docs.slice(i, i + BATCH_SIZE);

    for (const doc of slice) {
      const newPrecio = randomPrice();
      batch.update(doc.ref, {
        precio: newPrecio,
        price: FieldValue.delete(), // borra el campo viejo
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    done += slice.length;
    console.log(`  ✓ ${done} / ${docs.length} actualizados`);
  }

  console.log(`\nListo. ${docs.length} productos migrados a \`precio\`.`);
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
