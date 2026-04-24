// =============================================================================
// Arbol de categorias del catalogo: un solo sitio de verdad para el home, el
// mock y la pantalla [CatalogoStandaloneScreen]. Las claves son titulos
// visibles; [kCatalogGroupIdByTitle] expone un id alfanumerico para el backend.
// =============================================================================

/// IDs estables para API / backend (mismo titulo de grupo que [kCatalogHogar] y [kCatalogIndustrial]).
const Map<String, String> kCatalogGroupIdByTitle = <String, String>{
  'Cocina': 'cocina',
  'Artículos del Hogar': 'articulos_hogar',
  'Mascotas': 'mascotas',
  'Jardinería': 'jardineria',
  'Muebles': 'muebles',
  'Infantil': 'infantil',
  'Industrial': 'industrial',
};

/// Tab "Hogar" en [CatalogoScreen]: categoria mostrada a usuario → subtipos
/// que coinciden con [Product.category] en el mock o con el API.
const Map<String, List<String>> kCatalogHogar = <String, List<String>>{
  'Cocina': [
    'Envases',
    'Jarras',
    'Vasos',
    'Surtidor de Agua',
    'Escurridores',
    'Escurridores y Plateras',
    'Embudos',
    'Coladores',
    'Paneras',
    'Tablas de Cortar',
    'Hieleras',
    'Exprimidores',
  ],
  'Artículos del Hogar': [
    'Gaveteros',
    'Organizadores',
    'Cajas de Almacenamiento',
    'Canastas y Cestos',
    'Hampers',
    'Cubetas, Cubetas y Lebrillos',
    'Poncheras',
    'Zafacones',
  ],
  'Mascotas': ['Bacinillas'],
  'Jardinería': ['Tarros', 'Planters', 'Jardineras'],
  'Muebles': ['Mesas', 'Sillas', 'Muebles Rattan'],
  'Infantil': ['Silla', 'Cubeta bañito', 'Banqueta'],
};

/// Tab "Industrial" en [CatalogoScreen]: un grupo padre con tres subtipos.
const Map<String, List<String>> kCatalogIndustrial = <String, List<String>>{
  'Industrial': ['Crates', 'Otros', 'Pallets'],
};
