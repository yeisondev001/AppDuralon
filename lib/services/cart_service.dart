import 'dart:convert';

import 'package:app_duralon/models/cart_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  static const _kKey = 'dl_cart';

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalPiezas => _items.fold(0, (s, it) => s + it.cantidad);
  bool get isEmpty => _items.isEmpty;

  /// Carga el carrito guardado. Llamar una sola vez al iniciar la app.
  Future<void> hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.map((e) => _itemFromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(_items.map(_itemToJson).toList()));
    } catch (_) {}
  }

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      final it = _items[idx];
      final maxQty = it.stock > 0 ? it.stock : 99999;
      final minQty = it.minOrderQty > 0 ? it.minOrderQty : 1;
      it.cantidad = (it.cantidad + item.cantidad).clamp(minQty, maxQty);
    } else {
      _items.add(item);
    }
    notifyListeners();
    _persist();
  }

  void updateQty(String id, int delta) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final it = _items[idx];
    final maxQty = it.stock > 0 ? it.stock : 99999;
    final minQty = it.minOrderQty > 0 ? it.minOrderQty : 1;
    it.cantidad = (it.cantidad + delta).clamp(minQty, maxQty);
    notifyListeners();
    _persist();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  // ── Serialización ─────────────────────────────────────────────────────────────

  static Map<String, dynamic> _itemToJson(CartItem i) => {
        'id': i.id,
        'productId': i.productId,
        'codigo': i.codigo,
        'nombre': i.nombre,
        'categoria': i.categoria,
        if (i.color != null) 'color': i.color,
        'precio': i.precio,
        'cantidad': i.cantidad,
        'stock': i.stock,
        if (i.imageUrl != null) 'imageUrl': i.imageUrl,
        'stepQty': i.stepQty,
        'minOrderQty': i.minOrderQty,
      };

  static CartItem _itemFromJson(Map<String, dynamic> m) => CartItem(
        id: m['id'] as String,
        productId: m['productId'] as String,
        codigo: m['codigo'] as String,
        nombre: m['nombre'] as String,
        categoria: m['categoria'] as String,
        color: m['color'] as String?,
        precio: (m['precio'] as num).toDouble(),
        cantidad: (m['cantidad'] as num).toInt(),
        stock: (m['stock'] as num?)?.toInt() ?? 9999,
        imageUrl: m['imageUrl'] as String?,
        stepQty: (m['stepQty'] as num?)?.toInt() ?? 1,
        minOrderQty: (m['minOrderQty'] as num?)?.toInt() ?? 1,
      );
}
