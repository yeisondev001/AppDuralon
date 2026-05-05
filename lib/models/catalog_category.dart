// Representa una categoría del catálogo almacenada en Firestore
// (colección `catalog_categories`).
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.title,
    required this.tab,
    required this.order,
    required this.subtypes,
    this.titleEn,
    this.titleFr,
  });

  /// ID estable en Firestore (ej: "cocina", "articulos_hogar").
  final String id;

  /// Nombre visible en español (ej: "Cocina", "Artículos del Hogar").
  final String title;

  /// Nombre en inglés (opcional; si es null se usa [title]).
  final String? titleEn;

  /// Nombre en francés (opcional; si es null se usa [title]).
  final String? titleFr;

  /// Devuelve el título en el idioma indicado, con fallback a español.
  String titleFor(String lang) {
    if (lang == 'en' && titleEn != null && titleEn!.isNotEmpty) return titleEn!;
    if (lang == 'fr' && titleFr != null && titleFr!.isNotEmpty) return titleFr!;
    return title;
  }

  /// Tab al que pertenece: "hogar" | "industrial".
  final String tab;

  /// Posición de ordenamiento en la lista.
  final int order;

  /// Subtipos que muestra este grupo (ej: ["Envases", "Jarras"]).
  final List<String> subtypes;

  factory CatalogCategory.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return CatalogCategory(
      id: doc.id,
      title: d['title'] as String? ?? doc.id,
      titleEn: d['titleEn'] as String?,
      titleFr: d['titleFr'] as String?,
      tab: d['tab'] as String? ?? 'hogar',
      order: (d['order'] as num?)?.toInt() ?? 0,
      subtypes: List<String>.from(d['subtypes'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'tab': tab,
      'order': order,
      'subtypes': subtypes,
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
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      tab: tab ?? this.tab,
      order: order ?? this.order,
      subtypes: subtypes ?? this.subtypes,
    );
  }
}
