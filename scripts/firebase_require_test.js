try {
  const app = require('firebase/app');
  console.log('FIREBASE_REQUIRE_OK', typeof app.initializeApp);
} catch (e) {
  console.error('FIREBASE_REQUIRE_ERR', e.code || e.message);
  process.exit(1);
}
