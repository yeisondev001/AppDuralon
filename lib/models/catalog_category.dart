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

  /// Devuelve el título en el idioma indicado; cae en español si no hay traducción.
  String titleFor(String lang) {
    if (lang == 'en' && titleEn?.isNotEmpty == true) return titleEn!;
    if (lang == 'fr' && titleFr?.isNotEmpty == true) return titleFr!;
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
      if (titleEn != null) 'titleEn': titleEn,
      if (titleFr != null) 'titleFr': titleFr,
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
