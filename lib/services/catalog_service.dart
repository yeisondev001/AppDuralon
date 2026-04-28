// Servicio de acceso a la colección `catalog_categories` en Firestore.
// Expone streams, CRUD y una función de carga inicial con los datos base del catálogo.
import 'package:app_duralon/models/catalog_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogService {
  CatalogService._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('catalog_categories');

  // ── Lectura ──────────────────────────────────────────────────────────────────

  /// Stream de todas las categorías, ordenadas por [tab] y luego [order].
  static Stream<List<CatalogCategory>> streamAll() {
    return _col
        .orderBy('tab')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                CatalogCategory.fromFirestore(
                    d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Stream filtrado por tab ("hogar" | "industrial").
  static Stream<List<CatalogCategory>> streamByTab(String tab) {
    return _col
        .where('tab', isEqualTo: tab)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                CatalogCategory.fromFirestore(
                    d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Obtiene una sola vez la lista de categorías de un tab.
  static Future<List<CatalogCategory>> fetchByTab(String tab) async {
    final snap =
        await _col.where('tab', isEqualTo: tab).orderBy('order').get();
    return snap.docs
        .map((d) => CatalogCategory.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  // ── Escritura ─────────────────────────────────────────────────────────────────

  /// Agrega una nueva categoría. Usa el [id] si se especifica, si no genera uno.
  static Future<void> add(CatalogCategory category) async {
    final data = {
      ...category.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _col.doc(category.id).set(data);
  }

  /// Actualiza campos de una categoría existente.
  static Future<void> update(
      String id, Map<String, dynamic> fields) async {
    await _col.doc(id).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina una categoría. No elimina los productos asociados.
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ── Carga inicial ─────────────────────────────────────────────────────────────

  /// Estructura base del catálogo Hogar: título → subtipos.
  static const _hogar = <String, List<String>>{
    'Cocina': [
      'Envases', 'Jarras', 'Vasos', 'Surtidor de Agua',
      'Escurridores', 'Escurridores y Plateras', 'Embudos',
      'Coladores', 'Paneras', 'Tablas de Cortar', 'Hieleras', 'Exprimidores',
    ],
    'Artículos del Hogar': [
      'Gaveteros', 'Organizadores', 'Cajas de Almacenamiento',
      'Canastas y Cestos', 'Hampers', 'Cubetas, Cubetas y Lebrillos',
      'Poncheras', 'Zafacones',
    ],
    'Mascotas': ['Bacinillas'],
    'Jardinería': ['Tarros', 'Planters', 'Jardineras'],
    'Muebles': ['Mesas', 'Sillas', 'Muebles Rattan'],
    'Infantil': ['Silla', 'Cubeta bañito', 'Banqueta'],
  };

  /// Estructura base del catálogo Industrial: título → subtipos.
  static const _industrial = <String, List<String>>{
    'Industrial': ['Crates', 'Otros', 'Pallets'],
  };

  /// IDs estables en Firestore por título de grupo.
  static const _groupIds = <String, String>{
    'Cocina': 'cocina',
    'Artículos del Hogar': 'articulos_hogar',
    'Mascotas': 'mascotas',
    'Jardinería': 'jardineria',
    'Muebles': 'muebles',
    'Infantil': 'infantil',
    'Industrial': 'industrial',
  };

  /// Escribe en Firestore la estructura base del catálogo usando `set` con merge.
  /// Ejecutar una sola vez desde el Panel de administración → Catálogos → Cargar.
  static Future<void> seedFromLocalData() async {
    final batch = FirebaseFirestore.instance.batch();

    var order = 0;
    _hogar.forEach((title, subtypes) {
      final id = _groupIds[title] ?? _slugify(title);
      batch.set(_col.doc(id), {
        'title': title,
        'tab': 'hogar',
        'order': order++,
        'subtypes': subtypes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    order = 0;
    _industrial.forEach((title, subtypes) {
      final id = _groupIds[title] ?? _slugify(title);
      batch.set(_col.doc(id), {
        'title': title,
        'tab': 'industrial',
        'order': order++,
        'subtypes': subtypes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  static String _slugify(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
