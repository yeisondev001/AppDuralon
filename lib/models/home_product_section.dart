// Una fila del home: titulo de grupo (Cocina, etc.) + productos de preview.
// El [categoryId] corresponde al ID del documento en `catalog_categories` en Firestore.
import 'package:app_duralon/models/product.dart';

class HomeProductSection {
  const HomeProductSection({
    required this.categoryId,
    required this.title,
    required this.subtypes,
    required this.previewProducts,
  });

  /// ID del documento en la colección `catalog_categories` de Firestore.
  final String categoryId;

  /// Título visible de la categoría (ej: "Cocina", "Artículos del Hogar").
  final String title;

  /// Subtipos del catálogo que agrupa esta sección.
  final List<String> subtypes;

  /// Productos en carrusel (preview); puede ser un subconjunto o filtrado por búsqueda.
  final List<Product> previewProducts;
}
