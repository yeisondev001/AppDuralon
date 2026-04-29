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
  });

  final String id;
  final String productId;
  final String codigo;
  final String nombre;
  final String categoria;
  final String? color;
  final double precio;
  int cantidad;
  final int stock;

  double get total => precio * cantidad;

  static CartItem fromProduct(
    Product p,
    ProductVariant? variant,
    int qty,
    bool isDistribuidor,
  ) {
    final codigo = variant?.codigo.isNotEmpty == true ? variant!.codigo : p.id;
    final precio = variant != null
        ? (isDistribuidor ? variant.priceDistributor : variant.priceRetail)
        : p.price;
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
      cantidad: qty,
      stock: variant?.stock ?? 9999,
    );
  }
}
