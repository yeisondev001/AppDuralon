// Modelo de artículo: datos minimos en listas, grid y [ProductoScreen].
// Al integrar API, añade campos opcionales o un DTO; no rompe las pantallas actuales.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageAsset,
    this.listPrice,
    this.minOrderQty = 30,
    this.stepQty = 1,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageAsset;
  /// Precio anterior (tachado en detalle). Nulo = no mostrar.
  final double? listPrice;
  /// Cantidad minima para venta mayorista (ej: 30 unidades).
  final int minOrderQty;
  /// Salto/multiplo de compra (ej: 10 -> 30,40,50...).
  final int stepQty;
}
