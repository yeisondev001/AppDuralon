const admin = require('firebase-admin');
const serviceAccount = require('C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

async function deleteUserByEmail(email) {
  console.log(`Buscando usuario: ${email}`);
  const user = await auth.getUserByEmail(email);
  const uid = user.uid;
  console.log(`UID encontrado: ${uid}`);

  await Promise.all([
    db.collection('users').doc(uid).delete().then(() => console.log('Firestore users/ eliminado')),
    db.collection('customers').doc(uid).delete().then(() => console.log('Firestore customers/ eliminado')),
  ]);

  await auth.deleteUser(uid);
  console.log(`Auth account eliminada: ${email}`);
}

deleteUserByEmail('yeisonrojas03@gmail.com')
  .then(() => { console.log('Listo.'); process.exit(0); })
  .catch(err => { console.error('Error:', err.message); process.exit(1); });
