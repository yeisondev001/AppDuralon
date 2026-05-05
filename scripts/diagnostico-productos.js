/**
 * Diagnóstico de productos: cuenta documentos vacíos vs válidos,
 * agrupa por catalogId y verifica match contra catalog_categories.
 * Uso: node diagnostico-productos.js
 */
const admin = require('firebase-admin');
const fs    = require('fs');

const KEY_PATH = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
});

const db = admin.firestore();

async function main() {
  const [productsSnap, catsSnap] = await Promise.all([
    db.collection('products').get(),
    db.collection('catalog_categories').get(),
  ]);

  console.log('='.repeat(70));
  console.log('CATEGORÍAS DEL CATÁLOGO');
  console.log('='.repeat(70));
  catsSnap.docs.forEach(d => {
    const data = d.data();
    console.log(`  [${data.tab || '?'}] ${d.id}  (order=${data.order ?? '?'})  title="${data.title}"`);
    console.log(`        subtypes: ${(data.subtypes || []).join(', ')}`);
  });

  console.log('\n' + '='.repeat(70));
  console.log('PRODUCTOS');
  console.log('='.repeat(70));

  const totalDocs = productsSnap.size;
  let empty = 0;
  let activeTrue = 0;
  let activeFalse = 0;
  let noActive = 0;
  let noName = 0;
  const byCatalogId = {};
  const emptyDocs = [];

  productsSnap.docs.forEach(d => {
    const data = d.data();
    const keys = Object.keys(data);
    if (keys.length === 0) {
      empty++;
      emptyDocs.push(d.id);
      return;
    }
    if (data.isActive === true) activeTrue++;
    else if (data.isActive === false) activeFalse++;
    else noActive++;

    if (!data.name) noName++;

    const cid = data.catalogId || '(sin catalogId)';
    byCatalogId[cid] = (byCatalogId[cid] || 0) + 1;
  });

  console.log(`Total documentos:   ${totalDocs}`);
  console.log(`  Vacíos (sin campos): ${empty}`);
  console.log(`  isActive=true:       ${activeTrue}`);
  console.log(`  isActive=false:      ${activeFalse}`);
  console.log(`  Sin campo isActive:  ${noActive}`);
  console.log(`  Sin campo name:      ${noName}`);

  console.log('\nPor catalogId:');
  Object.entries(byCatalogId)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cid, n]) => console.log(`  ${cid.padEnd(25)} ${n}`));

  if (emptyDocs.length > 0) {
    console.log(`\nIDs de docs vacíos (primeros 30):`);
    console.log('  ' + emptyDocs.slice(0, 30).join(', '));
    if (emptyDocs.length > 30) console.log(`  ... y ${emptyDocs.length - 30} más`);
  }

  // Verificar match con catálogos
  console.log('\n' + '='.repeat(70));
  console.log('MATCH catalogId → catalog_categories');
  console.log('='.repeat(70));
  const catIds = new Set(catsSnap.docs.map(d => d.id));
  Object.keys(byCatalogId).forEach(cid => {
    if (cid === '(sin catalogId)') return;
    const exists = catIds.has(cid) ? '✓' : '✗ HUÉRFANO';
    console.log(`  ${cid.padEnd(25)} ${exists}`);
  });

  // Simular query streamAll: orderBy name + where isActive==true
  console.log('\n' + '='.repeat(70));
  console.log('SIMULACIÓN streamAll() — productos que aparecerán en home');
  console.log('='.repeat(70));
  const visibleSnap = await db.collection('products')
    .where('isActive', '==', true)
    .orderBy('name')
    .limit(500)
    .get();
  console.log(`Productos que pasarían streamAll(): ${visibleSnap.size}`);
  const visibleByCat = {};
  visibleSnap.docs.forEach(d => {
    const cid = d.data().catalogId || '(sin)';
    visibleByCat[cid] = (visibleByCat[cid] || 0) + 1;
  });
  Object.entries(visibleByCat)
    .sort((a, b) => b[1] - a[1])
    .forEach(([cid, n]) => console.log(`  ${cid.padEnd(25)} ${n}`));

  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
