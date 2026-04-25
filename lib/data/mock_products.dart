// Genera [mockProducts] con datos de prueba alineados a [kCatalogHogar] / industrial.
// Solo debe usarse cuando [AppConfig.useMockCatalog] es true (ver lib/config/app_config.dart).
// [addRow] repite categoria = subtipo de catalogo; Infantil/Industrial usan bucles fijos.
import 'package:app_duralon/models/product.dart';

const String _img = 'assets/images/duralon_logo.png';

/// Al menos 10 productos por **subtipo** del catálogo (tap en acordeón).
/// El filtro en [HomeScreen] usa `name` o `category` (contiene el texto, en minúsculas).
final List<Product> mockProducts = _buildMock();

List<Product> _buildMock() {
  final out = <Product>[];
  var n = 0; // contador de ids m-1, m-2, ...

  /// Crea [count] productos con el mismo [category] (texto = subtipo en catalogo).
  void addRow(String category, int count, String Function(int i) name) {
    for (var i = 1; i <= count; i++) {
      n++;
      out.add(Product(
        id: 'm-$n',
        name: name(i),
        category: category,
        price: 25 + (n % 50) * 7.0 + (i * 1.5),
        imageAsset: _img,
      ));
    }
  }

  // --- Cocina (10 c/u) ---
  addRow('Envases', 10, (i) => 'Envase hermetico linea pro $i');
  addRow('Jarras', 10, (i) => 'Jarra reforzada linea pro $i');
  addRow('Vasos', 10, (i) => 'Vaso apilable pack $i');
  addRow('Surtidor de Agua', 10, (i) => 'Surtidor agua despachador $i L');
  addRow('Escurridores', 10, (i) => 'Escurridor vajilla compacto $i');
  addRow('Escurridores y Plateras', 10, (i) => 'Escurridor platera 2 niveles $i');
  addRow('Embudos', 10, (i) => 'Embudo utilitario $i');
  addRow('Coladores', 10, (i) => 'Colador malla reforzada $i');
  addRow('Paneras', 10, (i) => 'Panera oval trenzada $i');
  addRow('Tablas de Cortar', 10, (i) => 'Tabla corte higienica $i');
  addRow('Hieleras', 10, (i) => 'Hielera camping cap $i L');
  addRow('Exprimidores', 10, (i) => 'Exprimidor citricos manual $i');

  // --- Artículos del hogar (10 c/u) ---
  addRow('Gaveteros', 10, (i) => 'Gavetero modular cajon $i');
  addRow('Organizadores', 10, (i) => 'Organizador apilable set $i');
  addRow('Cajas de Almacenamiento', 10, (i) => 'Caja almacen con tapa $i');
  addRow('Canastas y Cestos', 10, (i) => 'Canasta cesto multiuso $i');
  addRow('Hampers', 10, (i) => 'Hamper ropa c tapa $i');
  addRow('Cubetas, Cubetas y Lebrillos', 10, (i) => 'Cubeta reforzada $i L');
  addRow('Poncheras', 10, (i) => 'Ponchera con canilla $i');
  addRow('Zafacones', 10, (i) => 'Zafacon pedal soft close $i');

  // --- Mascotas ---
  addRow('Bacinillas', 10, (i) => 'Bacinilla mascota tam $i');

  // --- Jardinería (10 c/u) ---
  addRow('Tarros', 10, (i) => 'Tarro hermetico jardin $i');
  addRow('Planters', 10, (i) => 'Planter resina $i');
  addRow('Jardineras', 10, (i) => 'Jardinera ventana l $i');

  // --- Muebles (10 c/u) ---
  addRow('Mesas', 10, (i) => 'Mesa plastica reforzada $i');
  addRow('Sillas', 10, (i) => 'Silla apilable jardin $i');
  addRow('Muebles Rattan', 10, (i) => 'Set rattan mod $i');

  // --- Infantil: subtipos (clave en nombre) ---
  for (var i = 1; i <= 10; i++) {
    n++;
    out.add(Product(
      id: 'm-$n',
      name: 'Silla infantil reforzada nino $i',
      category: 'Infantil',
      price: 120 + i * 15.0,
      imageAsset: _img,
    ));
  }
  for (var i = 1; i <= 10; i++) {
    n++;
    out.add(Product(
      id: 'm-$n',
      name: 'Cubeta bañito ergonomica modelo $i',
      category: 'Infantil',
      price: 90 + i * 8.0,
      imageAsset: _img,
    ));
  }
  for (var i = 1; i <= 10; i++) {
    n++;
    out.add(Product(
      id: 'm-$n',
      name: 'Banqueta infantil antideslizante $i',
      category: 'Infantil',
      price: 70 + i * 6.0,
      imageAsset: _img,
    ));
  }

  // --- Industrial (10 c/u) ---
  addRow('Crates', 10, (i) => 'Crate carga reforzada $i');
  addRow('Otros', 10, (i) => 'Soporte accesorio industrial $i');
  addRow('Pallets', 10, (i) => 'Pallet estandar $i');
  for (var i = 1; i <= 10; i++) {
    n++;
    out.add(Product(
      id: 'm-$n',
      name: 'Bulto industrial surtido $i',
      category: 'Industrial',
      price: 500 + i * 40.0,
      imageAsset: _img,
    ));
  }

  return out;
}

// Mapea el titulo de grupo (ej. "Cocina", "Infantil") + lista de subtipos a
// filas concretas de [mockProducts]. Usado en [HomeScreen] y [productsForFullCategoryList].
/// Productos del mock que pertenecen a un grupo de catalogo (mismas claves que el arbol de categorias).
List<Product> productsForCatalogGroup(String groupTitle, List<String> subtypes) {
  if (groupTitle == 'Infantil') {
    return mockProducts.where((p) => p.category == 'Infantil').toList();
  }
  if (groupTitle == 'Industrial') {
    const industrial = <String>{'Crates', 'Otros', 'Pallets', 'Industrial'};
    return mockProducts.where((p) => industrial.contains(p.category)).toList();
  }
  final set = subtypes.toSet();
  return mockProducts.where((p) => set.contains(p.category)).toList();
}
