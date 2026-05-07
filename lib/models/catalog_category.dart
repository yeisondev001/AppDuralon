// Representa una categoría del catálogo almacenada en Firestore
// (colección `catalog_categories`).
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.title,
    this.titleEn,
    this.titleFr,
    required this.tab,
    required this.order,
    required this.subtypes,
  });

  /// ID estable en Firestore (ej: "cocina", "articulos_hogar").
  final String id;

  /// Nombre visible en español (ej: "Cocina", "Artículos del Hogar").
  final String title;
  final String? titleEn;
  final String? titleFr;

  String titleFor(String lang) {
    if (lang == 'en' && titleEn?.isNotEmpty == true) return titleEn!;
    if (lang == 'fr' && titleFr?.isNotEmpty == true) return titleFr!;
    return title;
  }

  /// Sección: "hogar" | "industrial".
  final String tab;

  /// Posición de ordenamiento en la lista.
  final int order;

  /// Subtipos que muestra este grupo (ej: ["Envases", "Jarras"]).
  final List<String> subtypes;

  factory CatalogCategory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return CatalogCategory(
      id:       doc.id,
      title:    (d['titulo']   ?? d['title'])    as String? ?? doc.id,
      titleEn:  (d['tituloEn'] ?? d['titleEn'])  as String?,
      titleFr:  (d['tituloFr'] ?? d['titleFr'])  as String?,
      tab:      (d['seccion']  ?? d['tab'])       as String? ?? 'hogar',
      order:    ((d['orden']   ?? d['order']) as num?)?.toInt() ?? 0,
      subtypes: List<String>.from(
          (d['subtipos'] ?? d['subtypes']) as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'titulo':   title,
      if (titleEn != null) 'tituloEn': titleEn,
      if (titleFr != null) 'tituloFr': titleFr,
      'seccion':  tab,
      'orden':    order,
      'subtipos': subtypes,
    };
  }

  CatalogCategory copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? titleFr,
    String? tab,
    int? order,
    List<String>? subtypes,
  }) {
    return CatalogCategory(
      id:       id       ?? this.id,
      title:    title    ?? this.title,
      titleEn:  titleEn  ?? this.titleEn,
      titleFr:  titleFr  ?? this.titleFr,
      tab:      tab      ?? this.tab,
      order:    order    ?? this.order,
      subtypes: subtypes ?? this.subtypes,
    );
  }
}
