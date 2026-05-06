import 'package:app_duralon/models/cart_item.dart';
import 'package:flutter/foundation.dart';

// Gestiona el carrito en memoria durante la sesión.
// Singleton + ChangeNotifier: un solo estado compartido que notifica a los
// listeners (CarritoScreen, contadores del header) cuando cambia el contenido.
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  // Lista inmutable para evitar mutaciones externas accidentales.
  List<CartItem> get items => List.unmodifiable(_items);
  // totalPiezas: suma de unidades totales (cantidad × packQty), no empaques.
  int get totalPiezas => _items.fold(0, (s, it) => s + it.cantidad);
  // totalCbm: volumen acumulado en metros cúbicos; null si algún producto no tiene dimensiones.
  double get totalCbm => _items.fold(0.0, (s, it) => s + (it.totalCbm ?? 0.0));
  bool get isEmpty => _items.isEmpty;

  // Si el producto ya está en el carrito, acumula cantidad respetando el stock.
  // stock == 0 significa "sin límite conocido" → se usa 99999 como tope práctico.
  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      final it = _items[idx];
      final maxQty = it.stock > 0 ? it.stock : 99999;
      it.cantidad = (it.cantidad + item.cantidad).clamp(1, maxQty);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  // delta positivo = incremento, negativo = decremento.
  // clamp(1, max) impide llegar a cero: para eliminar usar removeItem.
  void updateQty(String id, int delta) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final it = _items[idx];
    final maxQty = it.stock > 0 ? it.stock : 99999;
    it.cantidad = (it.cantidad + delta).clamp(1, maxQty);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // Llamado después de confirmar el pedido para dejar el carrito limpio.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
