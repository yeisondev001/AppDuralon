/**
 * Inspecciona un documento específico de products/.
 * Uso: node inspeccionar-doc.js BA22CM
 */
const admin = require('firebase-admin');
const fs    = require('fs');

const KEY_PATH = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
});

const db = admin.firestore();

async function main() {
  const ids = process.argv.slice(2);
  if (ids.length === 0) {
    // Buscar 5 docs sin name
    const snap = await db.collection('products').limit(800).get();
    const sinName = snap.docs.filter(d => !d.data().name).slice(0, 5);
    console.log(`Mostrando ${sinName.length} docs sin name:\n`);
    sinName.forEach(d => {
      console.log(`--- ${d.id} ---`);
      console.log(JSON.stringify(d.data(), null, 2));
      console.log();
    });
    process.exit(0);
  }

  for (const id of ids) {
    const doc = await db.collection('products').doc(id).get();
    console.log(`--- ${id} (exists=${doc.exists}) ---`);
    if (doc.exists) console.log(JSON.stringify(doc.data(), null, 2));
    console.log();
  }
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
