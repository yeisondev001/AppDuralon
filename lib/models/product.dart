// Modelo de artículo: datos minimos en listas, grid y [ProductoScreen].
// Al integrar API, añade campos opcionales o un DTO; no rompe las pantallas actuales.
import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.catalogId,
    this.tab,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  /// Subtipo visible (ej: "Envases", "Jarras"). Coincide con el subtype del catálogo.
  final String category;
  final double price;
  final String imageAsset;
  /// Precio anterior (tachado en detalle). Nulo = no mostrar.
  final double? listPrice;
  /// Cantidad minima para venta mayorista (ej: 30 unidades).
  final int minOrderQty;
  /// Salto/multiplo de compra (ej: 10 -> 30,40,50...).
  final int stepQty;
  /// ID de la categoría padre en Firestore (ej: "cocina", "articulos_hogar").
  final String? catalogId;
  /// Tab al que pertenece: "hogar" o "industrial".
  final String? tab;
  /// URL de imagen en Firebase Storage (futura). Tiene prioridad sobre [imageAsset].
  final String? imageUrl;
  /// false = oculto en la tienda (sin borrar el documento).
  final bool isActive;

  /// Imagen a mostrar: URL remota si existe, si no el asset local.
  String get displayImage => (imageUrl != null && imageUrl!.isNotEmpty)
      ? imageUrl!
      : imageAsset;

  /// Crea un [Product] desde un documento de Firestore.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawPrice = d['price'];
    final rawList = d['listPrice'];
    final rawMin = d['minOrderQty'];
    final rawStep = d['stepQty'];
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
      listPrice: rawList is num ? rawList.toDouble() : null,
      minOrderQty: rawMin is int ? rawMin : (rawMin is num ? rawMin.toInt() : 30),
      stepQty: rawStep is int ? rawStep : (rawStep is num ? rawStep.toInt() : 1),
      catalogId: d['catalogId'] as String?,
      tab: d['tab'] as String?,
      imageUrl: d['imageUrl'] as String?,
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  /// Convierte a Map para guardar en Firestore.
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      if (listPrice != null) 'listPrice': listPrice,
      'minOrderQty': minOrderQty,
      'stepQty': stepQty,
      'imageAsset': imageAsset,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (catalogId != null) 'catalogId': catalogId,
      if (tab != null) 'tab': tab,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageAsset,
    double? listPrice,
    int? minOrderQty,
    int? stepQty,
    String? catalogId,
    String? tab,
    String? imageUrl,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageAsset: imageAsset ?? this.imageAsset,
      listPrice: listPrice ?? this.listPrice,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      stepQty: stepQty ?? this.stepQty,
      catalogId: catalogId ?? this.catalogId,
      tab: tab ?? this.tab,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
