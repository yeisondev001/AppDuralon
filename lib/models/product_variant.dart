/// Variante de un producto: combinación única de color + tamaño.
/// Se guarda como array embebido dentro del documento de `products`.
class ProductVariant {
  const ProductVariant({
    required this.sku,
    required this.ean,
    required this.color,
    this.size,
    this.dimensions = const {},
    required this.packQty,
    required this.palletQty,
    required this.priceRetail,
    required this.priceDistributor,
    this.stock = 0,
    this.isActive = true,
  });

  /// Código interno (ej: "ENV-PRO-RJ-500").
  final String sku;

  /// Código de barras EAN.
  final String ean;

  /// Color de la variante. Usa "Surtido" cuando aplica.
  final String color;

  /// Tamaño o capacidad (ej: "500ml", "1L"). Nulo si no aplica.
  final String? size;

  /// Dimensiones físicas en cm/kg. Solo incluye las claves que existen:
  /// 'largo', 'ancho', 'alto', 'peso'. Nunca guardar null.
  final Map<String, double> dimensions;

  /// Unidades por caja (empaque).
  final int packQty;

  /// Cajas por pallet.
  final int palletQty;

  /// Precio por caja para cliente minorista (RD$).
  final double priceRetail;

  /// Precio por caja para cliente distribuidor (RD$).
  final double priceDistributor;

  /// Stock disponible en cajas.
  final int stock;

  final bool isActive;

  // ── Helpers ──────────────────────────────────────────────────
  bool get isSurtido => color.toLowerCase() == 'surtido';

  double? get largo => dimensions['largo'];
  double? get ancho => dimensions['ancho'];
  double? get alto  => dimensions['alto'];
  double? get peso  => dimensions['peso'];

  /// Precio por pallet para distribuidor.
  double get pricePerPallet => priceDistributor * palletQty;

  // ── Serialización ─────────────────────────────────────────────
  factory ProductVariant.fromMap(Map<String, dynamic> m) {
    final rawDims = m['dimensions'] as Map<String, dynamic>? ?? {};
    return ProductVariant(
      sku:               m['sku']  as String? ?? '',
      ean:               m['ean']  as String? ?? '',
      color:             m['color'] as String? ?? 'Sin color',
      size:              m['size']  as String?,
      dimensions:        rawDims.map((k, v) => MapEntry(k, (v as num).toDouble())),
      packQty:           (m['packQty']   as num?)?.toInt() ?? 1,
      palletQty:         (m['palletQty'] as num?)?.toInt() ?? 1,
      priceRetail:       (m['priceRetail']       as num?)?.toDouble() ?? 0,
      priceDistributor:  (m['priceDistributor']  as num?)?.toDouble() ?? 0,
      stock:             (m['stock'] as num?)?.toInt() ?? 0,
      isActive:          m['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sku':   sku,
      'ean':   ean,
      'color': color,
      if (size != null) 'size': size,
      if (dimensions.isNotEmpty) 'dimensions': dimensions,
      'packQty':   packQty,
      'palletQty': palletQty,
      'priceRetail':      priceRetail,
      'priceDistributor': priceDistributor,
      'stock':    stock,
      'isActive': isActive,
    };
  }

  ProductVariant copyWith({
    String? sku,
    String? ean,
    String? color,
    String? size,
    Map<String, double>? dimensions,
    int? packQty,
    int? palletQty,
    double? priceRetail,
    double? priceDistributor,
    int? stock,
    bool? isActive,
  }) {
    return ProductVariant(
      sku:              sku              ?? this.sku,
      ean:              ean              ?? this.ean,
      color:            color            ?? this.color,
      size:             size             ?? this.size,
      dimensions:       dimensions       ?? this.dimensions,
      packQty:          packQty          ?? this.packQty,
      palletQty:        palletQty        ?? this.palletQty,
      priceRetail:      priceRetail      ?? this.priceRetail,
      priceDistributor: priceDistributor ?? this.priceDistributor,
      stock:            stock            ?? this.stock,
      isActive:         isActive         ?? this.isActive,
    );
  }
}
