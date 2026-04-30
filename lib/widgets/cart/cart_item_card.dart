import 'package:app_duralon/models/cart_item.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final atMin = item.cantidad <= item.minOrderQty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
        ],
        border: Border.all(color: const Color(0x0A0F172A)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(imageUrl: item.imageUrl, categoria: item.categoria),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓD · ${item.codigo}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.categoria,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    if (item.color != null)
                      Text(
                        item.color!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _DashedDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              _QtyGroup(
                qty: item.cantidad,
                stepQty: item.stepQty,
                minQty: item.minOrderQty,
                atMin: atMin,
                onIncrement: onIncrement,
                onDecrement: onDecrement,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RD\$${_fmt(item.precio)} c/u',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RD\$${_fmt(item.total)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF94A3B8),
              ),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Quitar del pedido', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(double n) {
  final s = n.toStringAsFixed(0);
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
}

// ── Miniatura ─────────────────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  const _Thumb({required this.categoria, this.imageUrl});
  final String categoria;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: AppColors.lightBlue,
        alignment: Alignment.center,
        child: Text(
          categoria.isNotEmpty ? categoria[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
          ),
        ),
      );
}

// ── Contador por empaque ───────────────────────────────────────────────────────

class _QtyGroup extends StatelessWidget {
  const _QtyGroup({
    required this.qty,
    required this.stepQty,
    required this.minQty,
    required this.atMin,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final int stepQty;
  final int minQty;
  final bool atMin;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final byBox = stepQty > 1;
    // Número que se muestra en el contador: cajas si hay stepQty, unidades si no
    final displayCount = byBox ? (qty / stepQty).round() : qty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: atMin ? null : onDecrement,
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '$displayCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _QtyButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (byBox)
          Text(
            '${displayCount == 1 ? 'caja' : 'cajas'} · $qty unidades',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          )
        else
          Text(
            '${qty == 1 ? 'unidad' : 'unidades'}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: disabled ? const Color(0xFFCBD5E1) : AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      const w = 4.0, sp = 4.0;
      final count = (c.maxWidth / (w + sp)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(count, (_) {
          return SizedBox(
            width: w,
            height: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
            ),
          );
        }),
      );
    });
  }
}
