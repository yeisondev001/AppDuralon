import 'package:app_duralon/models/order.dart';
import 'package:app_duralon/pages/mis_pedidos_screen.dart';
import 'package:app_duralon/services/order_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

class OrdenesTab extends StatelessWidget {
  const OrdenesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: OrderService.streamAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Color(0xFFCBD5E1),
                ),
                SizedBox(height: 12),
                Text(
                  'Sin órdenes aún',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _AdminOrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order});
  final Order order;

  static const _statusOptions = [
    OrderStatus.pendiente,
    OrderStatus.confirmado,
    OrderStatus.enProceso,
    OrderStatus.enviado,
    OrderStatus.entregado,
    OrderStatus.cancelado,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName.isNotEmpty
                          ? order.customerName
                          : order.customerEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusChipAdmin(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.totalUnidades} uds · ${_fmtDate(order.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              Text(
                'RD\$${_fmtNum(order.total)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OrderStatus>(
                  initialValue: order.status,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  items: _statusOptions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (s) {
                    if (s != null) OrderService.updateStatus(order.id, s);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                color: AppColors.primaryBlue,
                tooltip: 'Ver detalle',
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OrdenDetalleScreen(order: order),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChipAdmin extends StatelessWidget {
  const _StatusChipAdmin({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  (Color, Color) _colors(OrderStatus s) {
    switch (s) {
      case OrderStatus.pendiente:
        return (const Color(0xFFB45309), const Color(0xFFFEF3C7));
      case OrderStatus.confirmado:
        return (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE));
      case OrderStatus.enProceso:
        return (const Color(0xFF7C3AED), const Color(0xFFEDE9FE));
      case OrderStatus.enviado:
        return (const Color(0xFF0F766E), const Color(0xFFCCFBF1));
      case OrderStatus.entregado:
        return (const Color(0xFF15803D), const Color(0xFFDCFCE7));
      case OrderStatus.cancelado:
        return (const Color(0xFFB91C1C), const Color(0xFFFFE5E8));
    }
  }
}

String _fmtNum(double n) => n
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
