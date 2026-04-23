import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onMenuTap,
    required this.onScannerTap,
    required this.onCartTap,
    required this.onSearchChanged,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onScannerTap;
  final VoidCallback onCartTap;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/duralon_logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SearchBar(
              hintText: 'Buscar productos',
              onChanged: onSearchChanged,
              leading: const Icon(Icons.search_rounded),
              trailing: [
                IconButton(
                  onPressed: onScannerTap,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Escanear codigo',
                ),
              ],
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: onCartTap,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0059B7).withValues(alpha: 0.12),
              foregroundColor: const Color(0xFF0059B7),
            ),
            icon: const Icon(Icons.shopping_cart_rounded, size: 24),
            tooltip: 'Carrito',
          ),
        ],
      ),
    );
  }
}
