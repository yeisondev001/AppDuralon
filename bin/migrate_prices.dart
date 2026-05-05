import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:app_duralon/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final rnd = Random();
  final col = FirebaseFirestore.instance.collection('products');
  final snap = await col.get();

  if (snap.docs.isEmpty) {
    print('No hay documentos en products.');
    return;
  }

  const batchSize = 400;
  var updated = 0;

  for (var i = 0; i < snap.docs.length; i += batchSize) {
    final end = min(i + batchSize, snap.docs.length);
    final batch = FirebaseFirestore.instance.batch();

    for (var j = i; j < end; j++) {
      final doc = snap.docs[j];
      final precioAleatorio = double.parse(
        (rnd.nextDouble() * 450 + 50).toStringAsFixed(2),
      );

      batch.update(doc.reference, {
        'precio': precioAleatorio,
        'price': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      updated++;
    }

    await batch.commit();
    print('Lote ${i ~/ batchSize + 1} aplicado (${end - i} docs).');
  }

  print('Migracion completada. Total actualizados: $updated');
}
