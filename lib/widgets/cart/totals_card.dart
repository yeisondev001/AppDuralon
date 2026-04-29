import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

class TotalsCard extends StatelessWidget {
  const TotalsCard({
    super.key,
    required this.subtotal,
    required this.descuento,
    required this.itbis,
    required this.total,
  });

  final double subtotal;
  final double descuento;
  final double itbis;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _row('Subtotal', subtotal),
          if (descuento > 0)
            _row('Descuento', -descuento, isDiscount: true),
          _row('ITBIS 18%', itbis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'RD\$${_fmt(total)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool isDiscount = false}) {
    final display = isDiscount
        ? '−RD\$${_fmt(value.abs())}'
        : 'RD\$${_fmt(value)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          Text(
            display,
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
}

String _fmt(double n) {
  final s = n.toStringAsFixed(0);
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
}
