import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.windows,
  );

  const csvPath =
      r'c:\Users\Usuarios\Desktop\plantillasappDuralon\precios_codigo_precio1.csv';
  final csvFile = File(csvPath);
  if (!csvFile.existsSync()) {
    debugPrint('No se encontro CSV: $csvPath');
    exit(1);
  }

  final col = FirebaseFirestore.instance.collection('products');
  final lines = csvFile.readAsLinesSync();
  if (lines.length <= 1) {
    debugPrint('CSV sin filas de datos.');
    exit(1);
  }

  final updates = <MapEntry<String, double>>[];
  var invalidRows = 0;
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final match = RegExp(r'^"?([^"]+)"?,"?([^"]+)"?$').firstMatch(line);
    if (match == null) {
      invalidRows++;
      continue;
    }
    final codigo = match.group(1)?.trim() ?? '';
    var precioTxt = match.group(2)?.trim() ?? '';
    precioTxt = precioTxt.replaceAll(',', '.');
    final precio = double.tryParse(precioTxt);
    if (codigo.isEmpty || precio == null) {
      invalidRows++;
      continue;
    }
    updates.add(MapEntry(codigo, precio));
  }

  if (updates.isEmpty) {
    debugPrint('No hay filas validas para actualizar.');
    exit(1);
  }

  const batchSize = 400;
  var updated = 0;
  var notFound = 0;

  for (var i = 0; i < updates.length; i += batchSize) {
    final end = min(i + batchSize, updates.length);
    final batch = FirebaseFirestore.instance.batch();
    for (var j = i; j < end; j++) {
      final item = updates[j];
      final ref = col.doc(item.key);
      final doc = await ref.get();
      if (!doc.exists) {
        notFound++;
        continue;
      }
      batch.update(ref, {
        'precio': item.value,
        'price': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      updated++;
    }
    await batch.commit();
    debugPrint(
        'Lote ${i ~/ batchSize + 1} aplicado (${end - i} filas procesadas).');
  }

  debugPrint(
    'Migracion completada. Actualizados: $updated | No encontrados: $notFound | Filas invalidas: $invalidRows',
  );
  exit(0);
}
