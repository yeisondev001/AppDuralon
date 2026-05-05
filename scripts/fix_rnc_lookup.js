/**
 * Script one-shot: crea el documento rnc_lookup/{rnc} para usuarios
 * existentes que aún no tienen esa entrada.
 *
 * Uso:
 *   node scripts/fix_rnc_lookup.js <rnc_o_cedula> <email> <password>
 *
 * Ejemplo:
 *   node scripts/fix_rnc_lookup.js 40233903158 pedromateo.desarrollo@gmail.com Yeison123
 */
const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc, serverTimestamp } = require('firebase/firestore');

const [,, rncRaw, email, password] = process.argv;
if (!rncRaw || !email || !password) {
  console.error('Uso: node scripts/fix_rnc_lookup.js <rnc> <email> <password>');
  process.exit(1);
}

const normalized = rncRaw.replace(/[^0-9]/g, '');
if (!normalized) {
  console.error('RNC/cédula inválido.');
  process.exit(1);
}

const firebaseConfig = {
  apiKey: 'AIzaSyDjN9UUKo503SwrXkVVRgrGy4UwtTOlbhk',
  authDomain: 'appduralon.firebaseapp.com',
  projectId: 'appduralon',
  storageBucket: 'appduralon.firebasestorage.app',
  messagingSenderId: '383683295145',
  appId: '1:383683295145:web:03b54cdc944c598bb536b8',
};

async function main() {
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);

  console.log(`Autenticando como ${email}...`);
  await signInWithEmailAndPassword(auth, email, password);
  console.log('Autenticado.');

  const ref = doc(db, 'rnc_lookup', normalized);
  await setDoc(ref, {
    correo: email.trim(),
    creadoEn: serverTimestamp(),
  }, { merge: true });

  console.log(`✓ Documento rnc_lookup/${normalized} creado con correo=${email}`);
  process.exit(0);
}

main().catch(e => {
  console.error('Error:', e.message);
  process.exit(1);
});
