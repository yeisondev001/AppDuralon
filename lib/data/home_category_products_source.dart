// Puente entre el modelo de seccion del home y el listado "Ver todos" / API.
// Conserva [categoryId] y [subtypes] en [HomeProductSection] para el futuro GET.
import 'package:app_duralon/config/app_config.dart';
import 'package:app_duralon/data/mock_products.dart';
import 'package:app_duralon/models/home_product_section.dart';
import 'package:app_duralon/models/product.dart';

/// Listado completo de una categoria de home (listado de [ProductosScreen] al pulsar *Ver todos*).
///
/// Con [AppConfig.useMockCatalog] == true: datos locales.
/// Con produccion: reemplaza la rama por `GET .../categories/{id}/products` o similar
/// usando [HomeProductSection.categoryId].
List<Product> productsForFullCategoryList(HomeProductSection section) {
  if (AppConfig.useMockCatalog) {
    return productsForCatalogGroup(section.title, section.subtypes);
  }
  // TODO(Backend): descomenta e implementa cuando [environment] == production.
  // return di.productRepository.listByCategoryId(section.categoryId);
  return const <Product>[];
}

/// Listado de preview para los carruseles del [HomeScreen] (misma categoria [groupTitle]).
List<Product> productsForHomeCategoryPreview(
  String groupTitle,
  List<String> subtypes,
) {
  if (AppConfig.useMockCatalog) {
    return productsForCatalogGroup(groupTitle, subtypes);
  }
  // TODO(Backend): GET paginado o primeros N productos por groupTitle / categoryId
  return const <Product>[];
}
