import 'package:app_duralon/models/cart_item.dart';
import 'package:flutter/foundation.dart';

class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalPiezas => _items.fold(0, (s, it) => s + it.cantidad);
  bool get isEmpty => _items.isEmpty;

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx].cantidad =
          (_items[idx].cantidad + item.cantidad).clamp(1, _items[idx].stock);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void updateQty(String id, int delta) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final it = _items[idx];
    it.cantidad = (it.cantidad + delta).clamp(1, it.stock);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
