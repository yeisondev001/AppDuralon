const fs = require('fs');
const path = require('path');
const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const {
  getFirestore,
  collection,
  getDocs,
  doc,
  writeBatch,
  serverTimestamp,
  deleteField,
} = require('firebase/firestore');

const EMAIL = process.env.ADMIN_EMAIL;
const PASSWORD = process.env.ADMIN_PASSWORD;
const CSV_PATH =
  process.env.CSV_PATH ||
  'c:/Users/Usuarios/Desktop/plantillasappDuralon/precios_codigo_precio1.csv';

if (!EMAIL || !PASSWORD) {
  console.error('Faltan ADMIN_EMAIL o ADMIN_PASSWORD.');
  process.exit(1);
}

const firebaseConfig = {
  apiKey: 'AIzaSyDjN9UUKo503SwrXkVVRgrGy4UwtTOlbhk',
  authDomain: 'appduralon.firebaseapp.com',
  projectId: 'appduralon',
  storageBucket: 'appduralon.firebasestorage.app',
  messagingSenderId: '383683295145',
  appId: '1:383683295145:web:03b54cdc944c598bb536b8',
  measurementId: 'G-XHBHHJ4RR9',
};

function parseCsvRows(csvText) {
  const lines = csvText.split(/\r?\n/).filter(Boolean);
  if (lines.length <= 1) return [];
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    const m = line.match(/^"?(.*?)"?,"?(.*?)"?$/);
    if (!m) continue;
    const codigo = (m[1] || '').trim();
    const precioText = (m[2] || '').trim().replace(',', '.');
    const precio = Number(precioText);
    if (!codigo || Number.isNaN(precio)) continue;
    rows.push({ codigo, precio });
  }
  return rows;
}

async function run() {
  const fullPath = path.resolve(CSV_PATH);
  if (!fs.existsSync(fullPath)) {
    throw new Error(`No existe CSV: ${fullPath}`);
  }
  const csv = fs.readFileSync(fullPath, 'utf8');
  const rows = parseCsvRows(csv);
  if (!rows.length) {
    throw new Error('CSV sin filas validas (codigo, precio1).');
  }

  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);

  const cred = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
  console.log(`AUTH_OK uid=${cred.user.uid}`);

  const snap = await getDocs(collection(db, 'products'));
  const existingIds = new Set(snap.docs.map((d) => d.id));
  console.log(`PRODUCTS_EN_FIREBASE=${existingIds.size}`);
  console.log(`FILAS_CSV=${rows.length}`);

  const validRows = rows.filter((r) => existingIds.has(r.codigo));
  const notFound = rows.length - validRows.length;

  const batchSize = 400;
  let updated = 0;
  for (let i = 0; i < validRows.length; i += batchSize) {
    const batch = writeBatch(db);
    const end = Math.min(i + batchSize, validRows.length);
    for (let j = i; j < end; j++) {
      const row = validRows[j];
      const ref = doc(db, 'products', row.codigo);
      batch.update(ref, {
        precio: row.precio,
        price: deleteField(),
        updatedAt: serverTimestamp(),
      });
      updated++;
    }
    await batch.commit();
    console.log(`LOTE_OK ${Math.floor(i / batchSize) + 1} (${end - i})`);
  }

  console.log(`DONE updated=${updated} not_found=${notFound}`);
}

run().catch((e) => {
  console.error('ERROR', e.code || e.message || e);
  process.exit(1);
});
