import 'package:app_duralon/models/order.dart';
import 'package:app_duralon/pages/mis_pedidos_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/services/order_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/widgets/cart/cart_item_card.dart';
import 'package:app_duralon/widgets/cart/coupon_field.dart';
import 'package:app_duralon/widgets/cart/totals_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CarritoScreen extends StatefulWidget {
  const CarritoScreen({super.key});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  final _cart = CartService.instance;

  String? _cuponCodigo;
  double _cuponDescuento = 0;
  String? _cuponEtiqueta;
  bool _cuponInvalido = false;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  void _aplicarCupon(String code) {
    final c = code.trim().toUpperCase();
    setState(() {
      if (c == 'DURALON10') {
        _cuponCodigo = c;
        _cuponDescuento = 0.10;
        _cuponEtiqueta = '10% descuento';
        _cuponInvalido = false;
      } else if (c == 'DIST5') {
        _cuponCodigo = c;
        _cuponDescuento = 0.05;
        _cuponEtiqueta = '5% distribuidor';
        _cuponInvalido = false;
      } else if (c.isNotEmpty) {
        _cuponCodigo = c;
        _cuponDescuento = 0;
        _cuponEtiqueta = 'Cupón inválido';
        _cuponInvalido = true;
      }
    });
  }

  void _quitarCupon() {
    setState(() {
      _cuponCodigo = null;
      _cuponDescuento = 0;
      _cuponEtiqueta = null;
      _cuponInvalido = false;
    });
  }

  bool _enviando = false;

  Future<void> _confirmarPedido(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notasController = TextEditingController();
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirmar pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${_cart.totalPiezas} unidades · RD\$${_fmtNum(_total)}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notasController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Notas de entrega (opcional)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Confirmar pedido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !context.mounted) return;

    setState(() => _enviando = true);
    try {
      final order = Order(
        id:            '',
        customerId:    user.uid,
        customerName:  user.displayName ?? '',
        customerEmail: user.email ?? '',
        status:        OrderStatus.pendiente,
        items: _cart.items.map((i) => OrderItem(
          productId: i.productId,
          codigo:    i.codigo,
          nombre:    i.nombre,
          categoria: i.categoria,
          color:     i.color,
          precio:    i.precio,
          cantidad:  i.cantidad,
          imageUrl:  i.imageUrl,
        )).toList(),
        subtotal:  _subtotal,
        descuento: _descuento,
        itbis:     _itbis,
        total:     _total,
        cupon:     _cuponCodigo,
        notas:     notasController.text.trim(),
        createdAt: DateTime.now(),
      );

      await OrderService.createOrder(order);
      _cart.clear();
      _quitarCupon();

      if (!context.mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const MisPedidosScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al confirmar pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _fmtNum(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  double get _subtotal =>
      _cart.items.fold(0, (s, it) => s + it.total);
  double get _descuento =>
      _cuponInvalido ? 0 : _subtotal * _cuponDescuento;
  double get _itbis => (_subtotal - _descuento) * 0.18;
  double get _total => _subtotal - _descuento + _itbis;

  @override
  Widget build(BuildContext context) {
    final items = _cart.items;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, user),
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty(context)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Text(
                          'PRODUCTOS · ${items.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...items.map((it) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CartItemCard(
                                item: it,
                                onIncrement: () =>
                                    _cart.updateQty(it.id, it.stepQty),
                                onDecrement: () =>
                                    _cart.updateQty(it.id, -it.stepQty),
                                onRemove: () => _cart.removeItem(it.id),
                              ),
                            )),
                        const SizedBox(height: 6),
                        CouponField(
                          onApply: _aplicarCupon,
                          onClear: _quitarCupon,
                          codigo: _cuponCodigo,
                          etiqueta: _cuponEtiqueta,
                          invalido: _cuponInvalido,
                        ),
                        const SizedBox(height: 14),
                        TotalsCard(
                          subtotal: _subtotal,
                          descuento: _descuento,
                          itbis: _itbis,
                          total: _total,
                        ),
                      ],
                    ),
            ),
            if (items.isNotEmpty) _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    final piezas = _cart.totalPiezas;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBox(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF0059B7),
                ),
              ),
              const Spacer(),
              const Text(
                'Mi pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                constraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$piezas',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user.displayName?.isNotEmpty == true
                              ? user.displayName![0]
                              : user.email?[0] ?? 'U')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.email ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega productos desde el catálogo',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Ver catálogo',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final totalStr =
        'RD\$${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_cart.totalPiezas} unidades',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                totalStr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _enviando ? null : () => _confirmarPedido(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _enviando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Confirmar pedido →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
