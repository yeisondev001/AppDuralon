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
    required this.imageAsset,
    this.description,
    this.listPrice,
    this.minOrderQty = 30,
    this.stepQty = 1,
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

  /// Precio base para compatibilidad. Usa [variants] para precios detallados.
  final double price;

  final String imageAsset;

  final String? description;

  /// Precio anterior (tachado). Nulo = no mostrar.
  final double? listPrice;

  /// Cantidad mínima de compra (en unidades o cajas según el rol).
  final int minOrderQty;

  /// Salto/múltiplo de compra.
  final int stepQty;

  /// ID de la categoría en `catalog_categories` (ej: "cocina").
  final String? catalogId;

  /// Tab al que pertenece: "hogar" | "industrial".
  final String? tab;

  /// URL de imagen principal en Firebase Storage.
  final String? imageUrl;

  /// Lista de URLs de imágenes adicionales.
  final List<String> imageUrls;

  /// Variantes del producto (color + tamaño + SKU + EAN + precios).
  final List<ProductVariant> variants;

  /// false = oculto en tienda sin borrar el documento.
  final bool isActive;

  // ── Helpers ──────────────────────────────────────────────────
  String get displayImage => (imageUrl != null && imageUrl!.isNotEmpty)
      ? imageUrl!
      : imageAsset;

  bool get hasVariants => variants.isNotEmpty;

  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  // ── Serialización ─────────────────────────────────────────────
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawPrice   = d['price'];
    final rawList    = d['listPrice'];
    final rawMin     = d['minOrderQty'];
    final rawStep    = d['stepQty'];
    final rawUrls    = d['imageUrls'] as List<dynamic>? ?? [];
    final rawVariants = d['variants'] as List<dynamic>? ?? [];

    return Product(
      id: doc.id,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? d['name'] as String
          : 'Producto ${doc.id}',
      category: (d['category'] as String?)?.trim().isNotEmpty == true
          ? d['category'] as String
          : 'General',
      price: rawPrice is num ? rawPrice.toDouble() : 0,
      imageAsset: (d['imageAsset'] as String?)?.trim().isNotEmpty == true
          ? d['imageAsset'] as String
          : 'assets/images/duralon_logo.png',
      description:  d['description'] as String?,
      listPrice:    rawList is num ? rawList.toDouble() : null,
      minOrderQty:  rawMin is int ? rawMin : (rawMin is num ? rawMin.toInt() : 30),
      stepQty:      rawStep is int ? rawStep : (rawStep is num ? rawStep.toInt() : 1),
      catalogId:    d['catalogId'] as String?,
      tab:          d['tab'] as String?,
      imageUrl:     d['imageUrl'] as String?,
      imageUrls:    rawUrls.map((e) => e.toString()).toList(),
      variants:     rawVariants
          .map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
          .toList(),
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name':       name,
      'category':   category,
      'price':      price,
      if (description != null)  'description': description,
      if (listPrice   != null)  'listPrice':   listPrice,
      'minOrderQty': minOrderQty,
      'stepQty':     stepQty,
      'imageAsset':  imageAsset,
      if (imageUrl != null)        'imageUrl':  imageUrl,
      if (imageUrls.isNotEmpty)    'imageUrls': imageUrls,
      if (catalogId != null)       'catalogId': catalogId,
      if (tab != null)             'tab':       tab,
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
    String? imageAsset,
    String? description,
    double? listPrice,
    int? minOrderQty,
    int? stepQty,
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
      imageAsset:  imageAsset  ?? this.imageAsset,
      description: description ?? this.description,
      listPrice:   listPrice   ?? this.listPrice,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      stepQty:     stepQty     ?? this.stepQty,
      catalogId:   catalogId   ?? this.catalogId,
      tab:         tab         ?? this.tab,
      imageUrl:    imageUrl    ?? this.imageUrl,
      imageUrls:   imageUrls   ?? this.imageUrls,
      variants:    variants    ?? this.variants,
      isActive:    isActive    ?? this.isActive,
    );
  }
}
