import 'package:app_duralon/data/mock_products.dart';
import 'package:app_duralon/models/home_product_section.dart';
import 'package:app_duralon/models/product.dart';

/// Listado completo de una categoria de home (listado de [ProductosScreen] al pulsar *Ver todos*).
///
/// Hoy: mock local. Para backend, sustituye el cuerpo por algo como
/// `await productRepository.fetchByCategoryId(section.categoryId)` y mapea el JSON a [Product].
List<Product> productsForFullCategoryList(HomeProductSection section) {
  return productsForCatalogGroup(section.title, section.subtypes);
}
