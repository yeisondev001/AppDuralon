import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    this.color,
    required this.precio,
    required this.cantidad,
    required this.stock,
    this.imageUrl,
    this.packQty = 1,
    this.cbmPerEmpaque,
  });

  final String id;
  final String productId;
  final String codigo;
  final String nombre;
  final String categoria;
  final String? color;
  final double precio;

  /// Número de empaques en el pedido.
  int cantidad;

  final int stock;
  final String? imageUrl;

  /// Unidades por empaque.
  final int packQty;

  /// CBM por empaque; null si el producto no tiene dimensiones.
  final double? cbmPerEmpaque;

  int get totalUnidades => cantidad * packQty;
  double? get totalCbm => cbmPerEmpaque != null ? cbmPerEmpaque! * cantidad : null;
  double get total => precio * cantidad;

  static CartItem fromProduct(
    Product p,
    ProductVariant? variant,
    int empaques,
    bool isDistribuidor,
  ) {
    final codigo = variant?.codigo.isNotEmpty == true ? variant!.codigo : p.id;
    final precio = variant != null
        ? (isDistribuidor ? variant.priceDistributor : variant.priceRetail)
        : p.price;
    final pack = (variant?.packQty ?? p.minOrderQty) > 0
        ? (variant?.packQty ?? p.minOrderQty)
        : 1;

    double? cbm;
    final dims = variant?.dimensions.isNotEmpty == true
        ? variant!.dimensions
        : p.dimensions;
    final l = dims['largo'];
    final a = dims['ancho'];
    final h = dims['alto'];
    if (l != null && a != null && h != null) {
      cbm = (l * a * h) / 1_000_000 * pack;
    }

    return CartItem(
      id: '${p.id}_$codigo',
      productId: p.id,
      codigo: codigo,
      nombre: p.name,
      categoria: p.category,
      color: (variant?.color.isNotEmpty == true && variant!.color != 'Sin color')
          ? variant.color
          : null,
      precio: precio,
      cantidad: empaques,
      stock: variant?.stock ?? 9999,
      imageUrl: p.imageUrl,
      packQty: pack,
      cbmPerEmpaque: cbm,
    );
  }
}
