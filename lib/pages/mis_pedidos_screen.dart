import 'package:app_duralon/models/order.dart';
import 'package:app_duralon/services/order_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class MisPedidosScreen extends StatelessWidget {
  const MisPedidosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis pedidos',
          style: TextStyle(
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Order>>(
        stream: OrderService.streamByCustomer(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar pedidos:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            );
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes pedidos aún',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tus órdenes aparecerán aquí',
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => OrdenDetalleScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pedido #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.totalUnidades} unidades · ${order.items.length} productos',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmtDate(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                Text(
                  'RD\$${_fmt(order.total)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detalle de orden ───────────────────────────────────────────────────────────

class OrdenDetalleScreen extends StatelessWidget {
  const OrdenDetalleScreen({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${order.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _StatusChip(status: order.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner cancelar (solo pendiente)
          if (order.status == OrderStatus.pendiente)
            _CancelBanner(order: order),
          if (order.status == OrderStatus.pendiente)
            const SizedBox(height: 12),

          // Info general
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Fecha', _fmtDate(order.createdAt)),
                _infoRow('Cliente', order.customerName.isNotEmpty ? order.customerName : order.customerEmail),
                if (order.notas != null && order.notas!.isNotEmpty)
                  _infoRow('Notas', order.notas!),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Productos
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PRODUCTOS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
          ),
          _Card(
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44, height: 44,
                        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _itemPlaceholder(item),
                              )
                            : _itemPlaceholder(item),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            '${item.cantidad} × RD\$${_fmt(item.precio)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'RD\$${_fmt(item.total)}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Totales
          _Card(
            child: Column(
              children: [
                _totalRow('Subtotal', order.subtotal),
                if (order.descuento > 0) _totalRow('Descuento', -order.descuento, isDiscount: true),
                _totalRow('ITBIS 18%', order.itbis),
                const Divider(height: 20, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(
                      'RD\$${_fmt(order.total)}',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(OrderItem item) => Container(
    width: 44, height: 44,
    color: AppColors.lightBlue,
    alignment: Alignment.center,
    child: Text(
      item.categoria.isNotEmpty ? item.categoria[0].toUpperCase() : 'D',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    ),
  );

  Widget _totalRow(String label, double value, {bool isDiscount = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        Text(
          isDiscount ? '−RD\$${_fmt(value.abs())}' : 'RD\$${_fmt(value)}',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.primaryRed : const Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: child,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  (Color, Color) _colors(OrderStatus s) {
    switch (s) {
      case OrderStatus.pendiente:  return (const Color(0xFFB45309), const Color(0xFFFEF3C7));
      case OrderStatus.confirmado: return (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE));
      case OrderStatus.enProceso:  return (const Color(0xFF7C3AED), const Color(0xFFEDE9FE));
      case OrderStatus.enviado:    return (const Color(0xFF0F766E), const Color(0xFFCCFBF1));
      case OrderStatus.entregado:  return (const Color(0xFF15803D), const Color(0xFFDCFCE7));
      case OrderStatus.cancelado:  return (const Color(0xFFB91C1C), const Color(0xFFFFE5E8));
    }
  }
}

// ── Banner cancelar pedido ─────────────────────────────────────────────────────

class _CancelBanner extends StatefulWidget {
  const _CancelBanner({required this.order});
  final Order order;

  @override
  State<_CancelBanner> createState() => _CancelBannerState();
}

class _CancelBannerState extends State<_CancelBanner> {
  bool _cancelling = false;

  Future<void> _cancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar pedido?'),
        content: const Text(
          'Esta acción no se puede deshacer. El pedido pasará a estado Cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    setState(() => _cancelling = true);
    try {
      await OrderService.updateStatus(widget.order.id, OrderStatus.cancelado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Puedes cancelar este pedido mientras esté pendiente.',
              style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
            ),
          ),
          const SizedBox(width: 10),
          _cancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB45309)),
                )
              : TextButton(
                  onPressed: () => _cancel(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: const Color(0xFFFFE5E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
        ],
      ),
    );
  }
}

String _fmt(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
