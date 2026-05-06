import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';

// Representa una línea del carrito: un producto+variante con su cantidad en empaques.
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
    this.pesoEmpaque,
    this.palletQty,
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

  /// CBM por empaque (m³); null si faltan dimensiones.
  final double? cbmPerEmpaque;

  /// Peso por empaque (kg); null si faltan dimensiones.
  final double? pesoEmpaque;

  /// Empaques por paleta; presente solo si el ítem se añadió en modo "por paleta".
  /// Se usa como flag de logística: si != null, el cliente pidió por paletas.
  final int? palletQty;

  int get totalUnidades => cantidad * packQty;
  double? get totalCbm => cbmPerEmpaque != null ? cbmPerEmpaque! * cantidad : null;
  // precio es por unidad → total = precio/und × und/paq × núm. paquetes
  double get total => precio * packQty * cantidad;

  // Construye un CartItem desde un producto y su variante seleccionada.
  // La variante tiene prioridad sobre el producto para código, precio y dimensiones.
  // [palletQty]: si se pasa, marca el ítem como "añadido por paleta" para logística.
  static CartItem fromProduct(
    Product p,
    ProductVariant? variant,
    int empaques,
    bool isDistribuidor, {
    int? palletQty,
  }) {
    final codigo = variant?.codigo.isNotEmpty == true ? variant!.codigo : p.id;
    final precio = variant != null
        ? (isDistribuidor ? variant.priceDistributor : variant.priceRetail)
        : p.price;
    // packQty == 0 no es válido; fallback a 1 para evitar división por cero en UI.
    final pack = (variant?.packQty ?? p.minOrderQty) > 0
        ? (variant?.packQty ?? p.minOrderQty)
        : 1;

    // CBM y peso por empaque desde dimensiones de la variante/producto.
    // largo/ancho/alto son dimensiones de una unidad; × pack = volumen/peso del empaque.
    double? cbm;
    double? peso;
    final dims = variant?.dimensions.isNotEmpty == true
        ? variant!.dimensions
        : p.dimensions;
    final l = dims['largo'];
    final a = dims['ancho'];
    final h = dims['alto'];
    final w = dims['peso'];
    if (l != null && a != null && h != null) {
      cbm = (l * a * h) / 1_000_000 * pack;
    }
    if (w != null && w > 0) {
      peso = w * pack;
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
      pesoEmpaque: peso,
      palletQty: palletQty,
    );
  }
}
