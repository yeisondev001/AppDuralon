// Servicio de acceso a la colección `catalog_categories` en Firestore.
import 'package:app_duralon/models/catalog_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogService {
  CatalogService._();

  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('catalog_categories');

  // ── Lectura ──────────────────────────────────────────────────────────────────

  /// Stream de todas las categorías, ordenadas por sección y luego orden.
  static Stream<List<CatalogCategory>> streamAll() {
    return _col
        .orderBy('seccion')
        .orderBy('orden')
        .snapshots()
        .map((snap) => _dedupe(snap.docs
            .map((d) => CatalogCategory.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList()));
  }

  /// Stream filtrado por sección ("hogar" | "industrial").
  static Stream<List<CatalogCategory>> streamByTab(String tab) {
    return _col
        .where('seccion', isEqualTo: tab)
        .orderBy('orden')
        .snapshots()
        .map((snap) => _dedupe(snap.docs
            .map((d) => CatalogCategory.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList()));
  }

  /// Obtiene una sola vez la lista de categorías de una sección.
  static Future<List<CatalogCategory>> fetchByTab(String tab) async {
    final snap =
        await _col.where('seccion', isEqualTo: tab).orderBy('orden').get();
    return snap.docs
        .map((d) => CatalogCategory.fromFirestore(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  // ── Escritura ─────────────────────────────────────────────────────────────────

  /// Agrega una nueva categoría.
  static Future<void> add(CatalogCategory category) async {
    final data = {
      ...category.toFirestore(),
      'creadoEn':      FieldValue.serverTimestamp(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    await _col.doc(category.id).set(data);
  }

  /// Actualiza campos de una categoría existente.
  static Future<void> update(String id, Map<String, dynamic> fields) async {
    await _col.doc(id).update({
      ...fields,
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina una categoría. No elimina los productos asociados.
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ── Carga inicial ─────────────────────────────────────────────────────────────

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
    'Jardinería': ['Tarros', 'Planters', 'Jardineras'],
    'Muebles': ['Mesas', 'Sillas', 'Muebles Rattan'],
    'Infantil': ['Silla', 'Cubeta bañito', 'Banqueta', 'Bacinillas'],
  };

  static const _industrial = <String, List<String>>{
    'Cajones Industriales': ['Cajón Estándar', 'Cajón Reciclado', 'Cajón Grande', 'Caja Logística'],
    'Otros': ['Conos', 'Accesorios Industriales'],
    'Paletas': ['Paleta Exportación', 'Paleta Racking', 'Paleta Carga Pesada', 'Paleta Estándar'],
  };

  static const _groupIds = <String, String>{
    'Cocina': 'cocina',
    'Artículos del Hogar': 'articulos_hogar',
    'Jardinería': 'jardineria',
    'Muebles': 'muebles',
    'Infantil': 'infantil',
    'Cajones Industriales': 'crates',
    'Otros': 'otros_ind',
    'Paletas': 'pallets',
  };

  static Future<void> seedFromLocalData() async {
    final batch = FirebaseFirestore.instance.batch();

    var orden = 0;
    _hogar.forEach((titulo, subtipos) {
      final id = _groupIds[titulo] ?? _slugify(titulo);
      batch.set(_col.doc(id), {
        'titulo':        titulo,
        'seccion':       'hogar',
        'orden':         orden++,
        'subtipos':      subtipos,
        'creadoEn':      FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });

    orden = 0;
    _industrial.forEach((titulo, subtipos) {
      final id = _groupIds[titulo] ?? _slugify(titulo);
      batch.set(_col.doc(id), {
        'titulo':        titulo,
        'seccion':       'industrial',
        'orden':         orden++,
        'subtipos':      subtipos,
        'creadoEn':      FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
  }

  static Future<void> migrateIndustrialIfNeeded() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      var needsCommit = false;

      final oldIndustrial = await _col.doc('industrial').get();
      if (oldIndustrial.exists) {
        final cratesDoc = await _col.doc('crates').get();
        if (!cratesDoc.exists) {
          var orden = 0;
          _industrial.forEach((titulo, subtipos) {
            final id = _groupIds[titulo] ?? _slugify(titulo);
            batch.set(_col.doc(id), {
              'titulo':        titulo,
              'seccion':       'industrial',
              'orden':         orden++,
              'subtipos':      subtipos,
              'creadoEn':      FieldValue.serverTimestamp(),
              'actualizadoEn': FieldValue.serverTimestamp(),
            });
          });
        }
        batch.delete(_col.doc('industrial'));
        needsCommit = true;
      }

      final mascotasDoc = await _col.doc('mascotas').get();
      if (mascotasDoc.exists) {
        final infantilId = _groupIds['Infantil'] ?? _slugify('Infantil');
        batch.update(_col.doc(infantilId), {
          'subtipos':      _hogar['Infantil'],
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
        batch.delete(_col.doc('mascotas'));
        needsCommit = true;
      }

      final hogarDoc = await _col.doc('hogar').get();
      final articulosHogarDoc = await _col.doc('articulos_hogar').get();
      if (hogarDoc.exists && articulosHogarDoc.exists) {
        batch.delete(_col.doc('articulos_hogar'));
        needsCommit = true;
      }

      if (needsCommit) await batch.commit();
    } catch (_) {
      // Silencioso — si falla por permisos no bloquea la app
    }
  }

  static const _canonicalIds = {
    'hogar', 'cocina', 'infantil', 'jardineria', 'muebles',
    'crates', 'otros_ind', 'pallets',
  };

  static List<CatalogCategory> _dedupe(List<CatalogCategory> cats) {
    final groups = <String, List<CatalogCategory>>{};
    for (final c in cats) {
      final key = '${c.tab}_${c.title.toLowerCase().trim()}';
      groups.putIfAbsent(key, () => []).add(c);
    }

    final seen = <String>{};
    final result = <CatalogCategory>[];
    for (final c in cats) {
      final key = '${c.tab}_${c.title.toLowerCase().trim()}';
      if (seen.add(key)) {
        final group = groups[key]!;
        final master = group.firstWhere(
          (g) => _canonicalIds.contains(g.id),
          orElse: () => group.first,
        );
        if (group.length > 1) {
          final merged = <String>{};
          for (final g in group) { merged.addAll(g.subtypes); }
          result.add(master.copyWith(subtypes: merged.toList()..sort()));
        } else {
          result.add(master);
        }
      }
    }
    return result;
  }

  static String _slugify(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
