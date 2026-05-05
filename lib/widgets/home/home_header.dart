import 'package:app_duralon/config/app_strings.dart';
import 'package:app_duralon/pages/carrito_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/services/locale_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/widgets/language_selector.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatefulWidget {
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
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final _cart = CartService.instance;

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

  @override
  Widget build(BuildContext context) {
    final cartCount = _cart.totalPiezas;
    final padH = MediaQuery.sizeOf(context).width < 360 ? 10.0 : 16.0;
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.instance,
      builder: (context, lang, child) => Padding(
      padding: EdgeInsets.fromLTRB(padH, 16, padH, 8),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: widget.onMenuTap,
            icon: const Icon(Icons.menu_rounded),
            tooltip: S.menuTooltip,
          ),
          const SizedBox(width: 2),
          Image.asset(
            'assets/images/duralon_logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SearchBar(
              hintText: S.searchHint,
              onChanged: widget.onSearchChanged,
              leading: const Icon(Icons.search_rounded),
              constraints: const BoxConstraints(minWidth: 0, minHeight: 48),
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ── Carrito ───────────────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const CarritoScreen()),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primaryBlue,
                ),
                icon: const Icon(Icons.shopping_cart_rounded, size: 22),
                tooltip: S.cartTooltip,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$cartCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          // ── Selector de idioma ────────────────────────────────────
          const LanguageSelectorButton(onSurface: true),
        ],
      ),
    ));
  }
}
