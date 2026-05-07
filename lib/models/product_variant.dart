/// Variante de un producto: combinación única de color + tamaño.
/// Se guarda como array embebido dentro del documento de `products`.
class ProductVariant {
  const ProductVariant({
    required this.codigo,
    required this.ean,
    required this.color,
    this.size,
    this.dimensions = const {},
    required this.packQty,
    required this.palletQty,
    required this.price,
    this.stock = 0,
    this.isActive = true,
  });

  final String codigo;
  final String ean;
  final String color;

  /// Tamaño o capacidad (ej: "500ml", "1L"). Nulo si no aplica.
  final String? size;

  /// Dimensiones físicas en cm/kg. Claves: 'largo', 'ancho', 'alto', 'peso'.
  final Map<String, double> dimensions;

  /// Unidades por caja (empaque).
  final int packQty;

  /// Cajas por pallet.
  final int palletQty;

  /// Precio base por caja (RD$). Los descuentos se aplican por cliente individualmente.
  final double price;

  /// Stock disponible en cajas.
  final int stock;

  final bool isActive;

  // ── Helpers ──────────────────────────────────────────────────
  bool get isSurtido => color.toLowerCase() == 'surtido';

  double? get largo => dimensions['largo'];
  double? get ancho => dimensions['ancho'];
  double? get alto  => dimensions['alto'];
  double? get peso  => dimensions['peso'];

  double get pricePerPallet => price * palletQty;

  // ── Serialización ─────────────────────────────────────────────
  factory ProductVariant.fromMap(Map<String, dynamic> m) {
    final rawDims = ((m['dimensiones'] ?? m['dimensions']) as Map<String, dynamic>?) ?? {};
    return ProductVariant(
      codigo:   m['codigo'] as String? ?? m['sku'] as String? ?? '',
      ean:      m['ean']    as String? ?? '',
      color:    m['color']  as String? ?? 'Sin color',
      size:     (m['talla'] ?? m['size']) as String?,
      dimensions: rawDims.map((k, v) => MapEntry(k, (v as num).toDouble())),
      packQty:  ((m['cantEmpaque'] ?? m['packQty'])   as num?)?.toInt() ?? 1,
      palletQty: ((m['cantPallet'] ?? m['palletQty']) as num?)?.toInt() ?? 1,
      price: (m['precio'] as num?)?.toDouble()
          ?? (m['price'] as num?)?.toDouble()
          ?? (m['priceRetail'] as num?)?.toDouble()
          ?? 0,
      stock:    ((m['stock']) as num?)?.toInt() ?? 0,
      isActive: (m['activo'] ?? m['isActive']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'codigo':     codigo,
      'ean':        ean,
      'color':      color,
      if (size != null)              'talla':      size,
      if (dimensions.isNotEmpty)     'dimensiones': dimensions,
      'cantEmpaque':  packQty,
      'cantPallet':   palletQty,
      'precio':       price,
      'stock':        stock,
      'activo':       isActive,
    };
  }

  ProductVariant copyWith({
    String? codigo,
    String? ean,
    String? color,
    String? size,
    Map<String, double>? dimensions,
    int? packQty,
    int? palletQty,
    double? price,
    int? stock,
    bool? isActive,
  }) {
    return ProductVariant(
      codigo:    codigo    ?? this.codigo,
      ean:       ean       ?? this.ean,
      color:     color     ?? this.color,
      size:      size      ?? this.size,
      dimensions: dimensions ?? this.dimensions,
      packQty:   packQty   ?? this.packQty,
      palletQty: palletQty ?? this.palletQty,
      price:     price     ?? this.price,
      stock:     stock     ?? this.stock,
      isActive:  isActive  ?? this.isActive,
    );
  }
}
