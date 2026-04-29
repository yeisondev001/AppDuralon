// Servicio centralizado para la colección `products` en Firestore.
// Reemplaza el acceso directo disperso en pantallas; usar en HomeScreen y admin.
import 'dart:math';

import 'package:app_duralon/models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  ProductService._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');
  static final Random _rnd = Random();

  // ── Streams ───────────────────────────────────────────────────────────────────

  /// Todos los productos activos en tiempo real, ordenados por nombre.
  static Stream<List<Product>> streamAll({bool activeOnly = true}) {
    Query<Map<String, dynamic>> q = _col.orderBy('name');
    if (activeOnly) {
      q = q.where('isActive', isEqualTo: true);
    }
    return q.snapshots().map(_mapSnap);
  }

  /// Productos activos filtrados por tab ("hogar" | "industrial").
  static Stream<List<Product>> streamByTab(String tab,
      {bool activeOnly = true}) {
    Query<Map<String, dynamic>> q =
        _col.where('tab', isEqualTo: tab).orderBy('name');
    if (activeOnly) {
      q = q.where('isActive', isEqualTo: true);
    }
    return q.snapshots().map(_mapSnap);
  }

  /// Productos filtrados por catalogId (ej: "cocina").
  static Stream<List<Product>> streamByCatalog(String catalogId,
      {bool activeOnly = true}) {
    Query<Map<String, dynamic>> q =
        _col.where('catalogId', isEqualTo: catalogId).orderBy('name');
    if (activeOnly) {
      q = q.where('isActive', isEqualTo: true);
    }
    return q.snapshots().map(_mapSnap);
  }

  /// Stream de TODOS los productos (sin filtro isActive), para el panel de admin.
  static Stream<List<Product>> streamAdmin() {
    return _col.orderBy('name').snapshots().map(_mapSnap);
  }

  // ── Escritura ─────────────────────────────────────────────────────────────────

  /// Agrega un nuevo producto. Retorna el ID generado.
  static Future<String> add(Map<String, dynamic> data) async {
    final payload = {
      ...data,
      'isActive': data['isActive'] ?? true,
      'imageAsset': data['imageAsset'] ?? 'assets/images/duralon_logo.png',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = await _col.add(payload);
    return ref.id;
  }

  /// Actualiza campos de un producto.
  static Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina permanentemente un producto.
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// Activa o desactiva un producto sin borrarlo.
  static Future<void> setActive(String id, {required bool active}) async {
    await _col.doc(id).update({
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Migra `price` -> `precio` y sobrescribe `precio` con valores aleatorios.
  ///
  /// Retorna la cantidad de documentos actualizados.
  static Future<int> migratePriceToPrecioWithRandomValues() async {
    final snap = await _col.get();
    if (snap.docs.isEmpty) return 0;

    const batchSize = 400;
    int updated = 0;

    for (int i = 0; i < snap.docs.length; i += batchSize) {
      final end = min(i + batchSize, snap.docs.length);
      final batch = FirebaseFirestore.instance.batch();

      for (int j = i; j < end; j++) {
        final doc = snap.docs[j];
        final precioAleatorio =
            double.parse((_rnd.nextDouble() * 450 + 50).toStringAsFixed(2));
        batch.update(doc.reference, {
          'precio': precioAleatorio,
          'price': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        updated++;
      }
      await batch.commit();
    }

    return updated;
  }

  // ── Helpers privados ──────────────────────────────────────────────────────────

  static List<Product> _mapSnap(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => Product.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }
}
