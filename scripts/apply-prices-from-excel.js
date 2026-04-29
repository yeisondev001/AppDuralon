// Actualiza precios en la colección `products` de Firestore.
// El ID de cada documento ES el mismo código del Excel (columna `codigo`).
// Campos actualizados por documento:
//   precio                      = precio1
//   precioDistribuidor          = precio2 (si > 0, sino precio1)
//   price                       → eliminado
//   variants[].priceRetail      = precio1  (para la variante cuyo codigo coincide)
//   variants[].priceDistributor = precio2  (para la variante cuyo codigo coincide)
//
// Uso (PowerShell desde la carpeta scripts/):
//   $env:GOOGLE_APPLICATION_CREDENTIALS="C:\ruta\a\serviceAccount.json"
//   node apply-prices-from-excel.js

const admin = require('firebase-admin');
const XLSX  = require('xlsx');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'appduralon',
});

const db         = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const BATCH_SIZE = 400;

const EXCEL_PATH = process.env.EXCEL_PATH ||
  'C:/Users/Usuarios/Desktop/plantillasappDuralon/precios.xlsx';

async function main() {
  // 1. Leer Excel → mapa  docId → { retail, dist }
  console.log(`Leyendo: ${EXCEL_PATH}`);
  const wb   = XLSX.readFile(EXCEL_PATH);
  const ws   = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws);

  const precioMap = {};
  for (const row of rows) {
    const codigo = String(row['codigo'] || '').trim();
    const retail = Number(row['precio1'] || 0);
    const dist   = Number(row['precio2'] || 0);
    if (!codigo) continue;
    if (retail > 0 || dist > 0) {
      precioMap[codigo] = {
        retail,
        dist: dist > 0 ? dist : retail,
      };
    }
  }
  console.log(`Códigos en Excel con precio: ${Object.keys(precioMap).length}`);

  // 2. Leer todos los documentos de la colección products
  console.log('Leyendo colección products...');
  const snap = await db.collection('products').get();
  console.log(`Documentos en Firestore: ${snap.docs.length}`);

  let matched   = 0;
  let unmatched = 0;
  let done      = 0;
  const sinMatch = [];

  for (let i = 0; i < snap.docs.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const slice = snap.docs.slice(i, i + BATCH_SIZE);

    for (const doc of slice) {
      const docId   = doc.id;
      const entrada = precioMap[docId];

      if (entrada) {
        matched++;
        const data     = doc.data();
        const variants = data.variants || [];

        // Actualizar variantes: asignar precio a la variante cuyo codigo coincide
        // Si ninguna variante tiene el mismo codigo, actualizar la primera.
        let variantsActualizadas = variants;
        if (variants.length > 0) {
          let actualizado = false;
          variantsActualizadas = variants.map((v) => {
            if (String(v.codigo || '').trim() === docId) {
              actualizado = true;
              return {
                ...v,
                priceRetail:      entrada.retail,
                priceDistributor: entrada.dist,
              };
            }
            return v;
          });
          // Si ninguna variante matcheó por codigo, actualizar todas
          if (!actualizado) {
            variantsActualizadas = variants.map((v) => ({
              ...v,
              priceRetail:      entrada.retail,
              priceDistributor: entrada.dist,
            }));
          }
        }

        batch.update(doc.ref, {
          precio:             entrada.retail,
          precioDistribuidor: entrada.dist,
          price:              FieldValue.delete(),
          variants:           variantsActualizadas,
          updatedAt:          FieldValue.serverTimestamp(),
        });
      } else {
        unmatched++;
        sinMatch.push(docId);
        // Solo renombrar price → precio sin cambiar el valor
        const data = doc.data();
        batch.update(doc.ref, {
          precio:    data.price ?? 0,
          price:     FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
    done += slice.length;
    console.log(`  ✓ ${done} / ${snap.docs.length}`);
  }

  console.log(`\n═══════════════════════════════════════`);
  console.log(`Con precio real (match): ${matched}`);
  console.log(`Sin match en Excel:      ${unmatched}`);
  console.log(`Total actualizados:      ${snap.docs.length}`);
  if (sinMatch.length > 0 && sinMatch.length <= 30) {
    console.log(`\nDocumentos sin match:`);
    sinMatch.forEach((id) => console.log(`  - ${id}`));
  }
  console.log(`═══════════════════════════════════════`);
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
