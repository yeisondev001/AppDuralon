import 'package:app_duralon/models/product.dart';

class HomeProductSection {
  const HomeProductSection({
    required this.categoryId,
    required this.title,
    required this.subtypes,
    required this.previewProducts,
  });

  /// Id estable para el backend, p. ej. `GET /v1/categories/cocina/products`.
  final String categoryId;

  /// Titulo visible (debe coincidir con claves de [kCatalogHogar] / [kCatalogIndustrial] mientras dure el mock).
  final String title;

  /// Subtipos del arbol; el mock resuelve con [productsForCatalogGroup].
  final List<String> subtypes;

  /// Productos en carrusel (preview); puede ser un subconjunto o filtrado por busqueda.
  final List<Product> previewProducts;
}
