/**
 * Genera un Excel con los productos que no tienen imageUrl en Firestore.
 * Uso: node reporte-productos-sin-foto.js
 */

const admin = require('firebase-admin');
const fs    = require('fs');
const XLSX  = require('xlsx');

const KEY_PATH = 'C:/Users/Usuarios/AppData/Local/firebase-keys/appduralon.json';
const OUTPUT   = 'C:/Users/Usuarios/Desktop/productos_sin_foto.xlsx';

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(KEY_PATH, 'utf8'))),
});

const CATALOG_LABELS = {
  cocina:     'Cocina',
  hogar:      'Artículos del Hogar',
  jardineria: 'Jardinería',
  muebles:    'Muebles',
  infantil:   'Infantil',
  crates:     'Cajones Industriales',
  otros_ind:  'Otros Industrial',
  pallets:    'Paletas',
};

const TAB_LABELS = { hogar: 'Hogar', industrial: 'Industrial' };

async function main() {
  const snap = await admin.firestore().collection('products').orderBy('catalogId').get();

  const sinFoto = snap.docs
    .filter(d => !d.data().imageUrl)
    .map(d => {
      const p = d.data();
      return {
        Código:    d.id,
        Nombre:    p.name    || '',
        Categoría: p.category || '',
        Catálogo:  CATALOG_LABELS[p.catalogId] || p.catalogId || '',
        Tab:       TAB_LABELS[p.tab] || p.tab || '',
        Activo:    p.isActive ? 'Sí' : 'No',
        'Archivo esperado': `${d.id}.jpg`,
      };
    });

  const conFoto = snap.docs.filter(d => d.data().imageUrl).length;

  console.log(`Total productos : ${snap.size}`);
  console.log(`Con foto        : ${conFoto}`);
  console.log(`Sin foto        : ${sinFoto.length}`);

  // ── Hoja 1: detalle ───────────────────────────────────────────
  const wsDetalle = XLSX.utils.json_to_sheet(sinFoto);

  // Anchos de columna
  wsDetalle['!cols'] = [
    { wch: 14 },  // Código
    { wch: 44 },  // Nombre
    { wch: 24 },  // Categoría
    { wch: 24 },  // Catálogo
    { wch: 12 },  // Tab
    { wch: 8  },  // Activo
    { wch: 18 },  // Archivo esperado
  ];

  // ── Hoja 2: resumen por catálogo ──────────────────────────────
  const porCatalogo = {};
  for (const row of sinFoto) {
    const key = row['Catálogo'];
    porCatalogo[key] = (porCatalogo[key] || 0) + 1;
  }
  const resumen = Object.entries(porCatalogo)
    .sort((a, b) => b[1] - a[1])
    .map(([cat, qty]) => ({ Catálogo: cat, 'Productos sin foto': qty }));

  resumen.push({ Catálogo: 'TOTAL', 'Productos sin foto': sinFoto.length });

  const wsResumen = XLSX.utils.json_to_sheet(resumen);
  wsResumen['!cols'] = [{ wch: 26 }, { wch: 20 }];

  // ── Workbook ──────────────────────────────────────────────────
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, wsDetalle, 'Productos sin foto');
  XLSX.utils.book_append_sheet(wb, wsResumen, 'Resumen por catálogo');

  XLSX.writeFile(wb, OUTPUT);
  console.log(`\n✓ Excel generado en: ${OUTPUT}`);
}

main().catch(err => { console.error('Error:', err.message); process.exit(1); });
