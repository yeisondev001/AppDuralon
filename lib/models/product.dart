// Modelo principal de artículo. Las variantes (color/tamaño/EAN/precios)
// se guardan como array embebido en el documento de Firestore.
import 'package:app_duralon/models/product_variant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameFr,
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
  final String? nameEn;
  final String? nameFr;

  /// Subtipo visible (ej: "Envases"). Coincide con el subtype del catálogo.
  final String category;

  /// Precio base (Firestore: campo `precio`).
  final double price;

  final String? description;
  final String? color;
  final String? ean;

  /// Precio anterior (tachado). Nulo = no mostrar.
  final double? listPrice;

  final int minOrderQty;
  final int stepQty;
  final int? palletQty;

  /// Dimensiones físicas en cm. Claves: 'largo', 'ancho', 'alto', 'peso'.
  final Map<String, double> dimensions;

  /// ID de la categoría en `catalog_categories`.
  final String? catalogId;

  /// Sección: "hogar" | "industrial".
  final String? tab;

  final String? imageUrl;
  final List<String> imageUrls;
  final List<ProductVariant> variants;

  /// false = oculto en tienda sin borrar el documento.
  final bool isActive;

  // ── Helpers ──────────────────────────────────────────────────
  String get displayImage =>
      (imageUrl != null && imageUrl!.isNotEmpty)
          ? imageUrl!
          : 'assets/images/duralon_logo.png';

  bool get hasVariants => variants.isNotEmpty;

  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  List<String> get parsedColors {
    if (color == null || color!.isEmpty) return const [];
    final c = color!.trim();
    if (c.toLowerCase() == 'varios' || c.toLowerCase() == 'surtido') {
      return const [];
    }
    return c.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  bool get isSurtido {
    final c = color?.trim().toLowerCase() ?? '';
    return c == 'surtido' || c == 'varios';
  }

  double? get largo => dimensions['largo'];
  double? get ancho => dimensions['ancho'];
  double? get alto  => dimensions['alto'];
  double? get peso  => dimensions['peso'];

  String nameFor(String lang) {
    if (lang == 'en' && nameEn?.isNotEmpty == true) return nameEn!;
    if (lang == 'fr' && nameFr?.isNotEmpty == true) return nameFr!;
    return name;
  }

  // ── Serialización ─────────────────────────────────────────────
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};

    // Lee campo español primero; fallback al inglés para docs antiguos.
    final rawPrecio    = d['precio']     ?? d['price'];
    final rawList      = d['precioLista'] ?? d['listPrice'];
    final rawMin       = d['cantMinima']  ?? d['minOrderQty'];
    final rawStep      = d['cantPaso']    ?? d['stepQty'];
    final rawPallet    = d['cantPallet']  ?? d['palletQty'];
    final rawUrls      = (d['urlImagenes'] ?? d['imageUrls']) as List<dynamic>? ?? [];
    final rawVariants  = (d['variantes']   ?? d['variants'])  as List<dynamic>? ?? [];
    final rawDims      = ((d['dimensiones'] ?? d['dimensions']) as Map<String, dynamic>?) ?? {};

    return Product(
      id: doc.id,
      name: ((d['nombre'] ?? d['name']) as String?)?.trim().isNotEmpty == true
          ? (d['nombre'] ?? d['name']) as String
          : 'Producto ${doc.id}',
      nameEn: d['nombreEn'] as String?,
      nameFr: d['nombreFr'] as String?,
      category: ((d['categoria'] ?? d['category']) as String?)?.trim().isNotEmpty == true
          ? (d['categoria'] ?? d['category']) as String
          : 'General',
      price:       rawPrecio is num ? rawPrecio.toDouble() : 0,
      description: (d['descripcion'] ?? d['description']) as String?,
      color:       d['color'] as String?,
      ean:         d['ean']   as String?,
      listPrice:   rawList is num ? rawList.toDouble() : null,
      minOrderQty: rawMin is int ? rawMin : (rawMin is num ? rawMin.toInt() : 1),
      stepQty:     rawStep is int ? rawStep : (rawStep is num ? rawStep.toInt() : 1),
      palletQty:   rawPallet is int ? rawPallet : (rawPallet is num ? rawPallet.toInt() : null),
      dimensions:  rawDims.map((k, v) => MapEntry(k, (v as num).toDouble())),
      catalogId:   (d['catalogoId'] ?? d['catalogId']) as String?,
      tab:         (d['seccion']    ?? d['tab'])        as String?,
      imageUrl:    (d['urlImagen']  ?? d['imageUrl'])   as String?,
      imageUrls:   rawUrls.map((e) => e.toString()).toList(),
      variants:    rawVariants
          .map((e) => ProductVariant.fromMap(e as Map<String, dynamic>))
          .toList(),
      isActive: (d['activo'] ?? d['isActive']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'nombre':    name,
      'categoria': category,
      'precio':    price,
      if (nameEn != null)      'nombreEn':   nameEn,
      if (nameFr != null)      'nombreFr':   nameFr,
      if (description != null) 'descripcion': description,
      if (color != null)       'color':      color,
      if (ean   != null)       'ean':        ean,
      if (listPrice != null)   'precioLista': listPrice,
      'cantMinima':  minOrderQty,
      'cantPaso':    stepQty,
      if (palletQty != null)       'cantPallet':  palletQty,
      if (dimensions.isNotEmpty)   'dimensiones': dimensions,
      if (imageUrl != null)        'urlImagen':   imageUrl,
      if (imageUrls.isNotEmpty)    'urlImagenes': imageUrls,
      if (catalogId != null)       'catalogoId':  catalogId,
      if (tab != null)             'seccion':     tab,
      if (variants.isNotEmpty)
        'variantes': variants.map((v) => v.toMap()).toList(),
      'activo': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? nameFr,
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
      nameEn:      nameEn      ?? this.nameEn,
      nameFr:      nameFr      ?? this.nameFr,
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
