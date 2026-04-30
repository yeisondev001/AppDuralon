// Modelo principal de artículo. Las variantes (color/tamaño/EAN/precios)
// se guardan como array embebido en el documento de Firestore.
import 'package:app_duralon/models/product_variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.color,
    this.ean,
    this.listPrice,
    this.minOrderQty = 1,
    this.stepQty = 1,
    this.palletQty,
    this.dimensions = const {},
    this.catalogId,
    this.tab,
    this.imageUrl,
    this.imageUrls = const [],
    this.variants = const [],
    this.isActive = true,
  });

  final String id;

  final String name;

  /// Subtipo visible (ej: "Envases"). Coincide con el subtype del catálogo.
  final String category;

  /// Precio base (**Firestore:** campo `precio`; el nombre en inglés `price` está obsoleto).
  final double price;

  final String? description;

  /// Color(es) del producto. Puede ser "Blanco/Crema/Azul" o "Surtido" o "Varios".
  final String? color;

  /// Código de barras EAN del producto base.
  final String? ean;

  /// Precio anterior (tachado). Nulo = no mostrar.
  final double? listPrice;

  /// Cantidad mínima de compra (unidades/cajas).
  final int minOrderQty;

  /// Salto/múltiplo de compra.
  final int stepQty;

  /// Cajas por pallet.
  final int? palletQty;

  /// Dimensiones físicas en cm. Claves posibles: 'largo', 'ancho', 'alto', 'peso'.
  final Map<String, double> dimensions;

  /// ID de la categoría en `catalog_categories` (ej: "cocina").
  final String? catalogId;

  /// Tab al que pertenece: "hogar" | "industrial".
  final String? tab;

  /// URL de imagen principal en Firebase Storage.
  final String? imageUrl;

  /// URLs de imágenes adicionales.
  final List<String> imageUrls;

  /// Variantes (color + tamaño + código + EAN + precios por rol).
  final List<ProductVariant> variants;

  /// false = oculto en tienda sin borrar el documento.
  final bool isActive;

  // ── Helpers ──────────────────────────────────────────────────
  /// Devuelve [imageUrl] si está disponible, o el logo local como fallback.
  String get displayImage =>
      (imageUrl != null && imageUrl!.isNotEmpty)
          ? imageUrl!
          : 'assets/images/duralon_logo.png';

  bool get hasVariants => variants.isNotEmpty;

  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  /// Devuelve la lista de colores individuales a partir del campo [color].
  /// "Blanco/Crema/Azul" → ['Blanco','Crema','Azul']
  /// "Surtido" / "Varios" → lista vacía (indica surtido, sin selección posible)
  List<String> get parsedColors {
    if (color == null || color!.isEmpty) return const [];
    final c = color!.trim();
    if (c.toLowerCase() == 'varios' || c.toLowerCase() == 'surtido') {
      return const [];
    }
    return c.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// true si el color es surtido o varios (no se puede elegir individualmente).
  bool get isSurtido {
    final c = color?.trim().toLowerCase() ?? '';
    return c == 'surtido' || c == 'varios';
  }

  double? get largo => dimensions['largo'];
  double? get ancho => dimensions['ancho'];
  double? get alto  => dimensions['alto'];
  double? get peso  => dimensions['peso'];

  // ── Serialización ─────────────────────────────────────────────
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawPrecio = d['precio'] ?? d['price']; // compat: docs antiguos con `price`
    final rawList     = d['listPrice'];
    final rawMin      = d['minOrderQty'];
    final rawStep     = d['stepQty'];
    final rawPallet   = d['palletQty'];
    final rawUrls     = d['imageUrls'] as List<dynamic>? ?? [];
    final rawVariants = d['variants']  as List<dynamic>? ?? [];
    final rawDims     = d['dimensions'] as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? d['name'] as String
          : 'Producto ${doc.id}',
      category: (d['category'] as String?)?.trim().isNotEmpty == true
          ? d['category'] as String
          : 'General',
      price:       rawPrecio is num ? rawPrecio.toDouble() : 0,
      description: d['description'] as String?,
      color:       d['color'] as String?,
      ean:         d['ean']   as String?,
      listPrice:   rawList is num ? rawList.toDouble() : null,
      minOrderQty: rawMin is int ? rawMin : (rawMin is num ? rawMin.toInt() : 1),
      stepQty:     rawStep is int ? rawStep : (rawStep is num ? rawStep.toInt() : 1),
      palletQty:   rawPallet is int ? rawPallet : (rawPallet is num ? rawPallet.toInt() : null),
      dimensions:  rawDims.map((k, v) => MapEntry(k, (v as num).toDouble())),
      catalogId:   d['catalogId'] as String?,
      tab:         d['tab']      as String?,
      imageUrl:    d['imageUrl'] as String?,
      imageUrls:   rawUrls.map((e) => e.toString()).toList(),
      variants:    rawVariants
          .map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
          .toList(),
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name':       name,
      'category':   category,
      'precio':     price,
      if (description != null) 'description': description,
      if (color != null)       'color':       color,
      if (ean   != null)       'ean':         ean,
      if (listPrice != null)   'listPrice':   listPrice,
      'minOrderQty': minOrderQty,
      'stepQty':     stepQty,
      if (palletQty != null)       'palletQty':  palletQty,
      if (dimensions.isNotEmpty)   'dimensions': dimensions,
      if (imageUrl != null)        'imageUrl':   imageUrl,
      if (imageUrls.isNotEmpty)    'imageUrls':  imageUrls,
      if (catalogId != null)       'catalogId':  catalogId,
      if (tab != null)             'tab':        tab,
      if (variants.isNotEmpty)
        'variants': variants.map((v) => v.toMap()).toList(),
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
    String? color,
    String? ean,
    double? listPrice,
    int? minOrderQty,
    int? stepQty,
    int? palletQty,
    Map<String, double>? dimensions,
    String? catalogId,
    String? tab,
    String? imageUrl,
    List<String>? imageUrls,
    List<ProductVariant>? variants,
    bool? isActive,
  }) {
    return Product(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      category:    category    ?? this.category,
      price:       price       ?? this.price,
      description: description ?? this.description,
      color:       color       ?? this.color,
      ean:         ean         ?? this.ean,
      listPrice:   listPrice   ?? this.listPrice,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      stepQty:     stepQty     ?? this.stepQty,
      palletQty:   palletQty   ?? this.palletQty,
      dimensions:  dimensions  ?? this.dimensions,
      catalogId:   catalogId   ?? this.catalogId,
      tab:         tab         ?? this.tab,
      imageUrl:    imageUrl    ?? this.imageUrl,
      imageUrls:   imageUrls   ?? this.imageUrls,
      variants:    variants    ?? this.variants,
      isActive:    isActive    ?? this.isActive,
    );
  }
}
