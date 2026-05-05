/**
 * Script one-shot: crea cuenta de admin en Firebase Auth + Firestore.
 * Ejecutar UNA sola vez.
 *   node scripts/create_admin.js
 */
const { initializeApp } = require('firebase/app');
const {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} = require('firebase/auth');
const {
  getFirestore,
  doc,
  setDoc,
  serverTimestamp,
} = require('firebase/firestore');

const EMAIL    = '40233903158@duralon.com';
const PASSWORD = 'Yeison123';
const RNC      = '40233903158';

const firebaseConfig = {
  apiKey: 'AIzaSyDjN9UUKo503SwrXkVVRgrGy4UwtTOlbhk',
  authDomain: 'appduralon.firebaseapp.com',
  projectId: 'appduralon',
  storageBucket: 'appduralon.firebasestorage.app',
  messagingSenderId: '383683295145',
  appId: '1:383683295145:web:03b54cdc944c598bb536b8',
};

async function main() {
  const app  = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db   = getFirestore(app);

  let uid;

  // Intentar crear; si ya existe, hacer login para obtener el UID
  try {
    console.log('Creando cuenta Firebase Auth...');
    const cred = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD);
    uid = cred.user.uid;
    console.log('Cuenta creada. UID:', uid);
  } catch (e) {
    if (e.code === 'auth/email-already-in-use') {
      console.log('La cuenta ya existe. Haciendo login para obtener UID...');
      const cred = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
      uid = cred.user.uid;
      console.log('Login OK. UID:', uid);
    } else {
      throw e;
    }
  }

  const now = serverTimestamp();

  // users/{uid}
  await setDoc(doc(db, 'users', uid), {
    uid,
    clienteId: uid,
    correo: EMAIL,
    nombre: 'Admin Duralon',
    fotoUrl: '',
    rol: 'admin',
    estado: 'activo',
    proveedorLogin: 'password',
    creadoEn: now,
    actualizadoEn: now,
  }, { merge: true });
  console.log('✓ users/' + uid);

  // customers/{uid}
  await setDoc(doc(db, 'customers', uid), {
    clienteId: uid,
    identificacion: RNC,
    identificacionNormalizada: RNC,
    tipoIdentificacion: 'cedula',
    cedula: RNC,
    cedulaNormalizado: RNC,
    tipoContribuyente: 'persona_fisica',
    nombreCompleto: 'Admin Duralon',
    telefono: '',
    correo: EMAIL,
    direccionFiscal: '',
    ciudad: 'Santo Domingo',
    pais: 'República Dominicana',
    estado: 'activo',
    creditoHabilitado: true,
    proveedorLogin: 'password',
    creadoEn: now,
    actualizadoEn: now,
  }, { merge: true });
  console.log('✓ customers/' + uid);

  // rnc_lookup/{rnc}
  await setDoc(doc(db, 'rnc_lookup', RNC), {
    correo: EMAIL,
    creadoEn: now,
  }, { merge: true });
  console.log('✓ rnc_lookup/' + RNC);

  console.log('\n✅ Cuenta admin lista.');
  console.log('   RNC:        ' + RNC);
  console.log('   Contraseña: ' + PASSWORD);
  console.log('   Rol:        admin');
  process.exit(0);
}

main().catch(e => {
  console.error('Error:', e.code, e.message);
  process.exit(1);
});
