import 'package:flutter/material.dart';
import 'package:app_duralon/styles/app_style.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onMenuTap,
    required this.onCartTap,
    required this.onSearchChanged,
  });

  final VoidCallback onMenuTap;
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
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: onCartTap,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
              foregroundColor: AppColors.primaryBlue,
            ),
            icon: const Icon(Icons.shopping_cart_rounded, size: 24),
            tooltip: 'Carrito',
          ),
        ],
      ),
    );
  }
}
