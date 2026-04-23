import 'package:app_duralon/data/mock_products.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/home/home_header.dart';
import 'package:app_duralon/widgets/home/horizontal_product_list.dart';
import 'package:app_duralon/widgets/home/main_categories_banner.dart';
import 'package:app_duralon/widgets/home/home_side_menu.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isGuestMode,
    this.userName,
  });

  final bool isGuestMode;
  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;
  String _searchQuery = '';
  int _selectedStoreTab = 0;

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
    }
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesion para usar carrito o comprar.'),
      ),
    );
  }

  void _handleCartTap(BuildContext context, Product? product) {
    if (widget.isGuestMode) {
      _showLoginRequired(context);
      return;
    }
    final productName = product == null ? '' : ' (${product.name})';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agregado al carrito$productName')),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estara disponible pronto.')),
    );
  }

  List<Product> get _filteredProducts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return mockProducts;
    return mockProducts.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildStoreTabs() {
    const labels = ['DURALON', 'DURALON'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = _selectedStoreTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedStoreTab = index),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF1E2A3A)
                            : const Color(0xFF74839B),
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 3,
                      width: 74,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFE21026) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HomeHeader(
            onMenuTap: _toggleMenu,
            onScannerTap: () => _showComingSoon(context, 'El escaner'),
            onCartTap: () => _handleCartTap(context, null),
            onSearchChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        SliverToBoxAdapter(child: _buildStoreTabs()),
        const SliverToBoxAdapter(child: MainCategoriesBanner()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.trim().isEmpty
                      ? 'Productos nuevos'
                      : 'Resultados para "${_searchQuery.trim()}"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (_searchQuery.trim().isEmpty)
                  FilledButton(
                    onPressed: () => _showComingSoon(context, 'Ver todos'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE4E8),
                      foregroundColor: const Color(0xFFE21026),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_filteredProducts.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se encontraron productos con esa busqueda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5C6B82),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: HorizontalProductList(
              products: _filteredProducts,
              onAddToCart: (product) => _handleCartTap(context, product),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: Stack(
          children: [
            HomeSideMenu(
              onItemTap: (item) {
                _closeMenu();
                _showComingSoon(context, item);
              },
              onLoginTap: () {
                _closeMenu();
                Navigator.push<void>(
                  context,
                  slideRightRoute<void>(const LoginScreen()),
                );
              },
            ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              offset: _isMenuOpen ? const Offset(0.72, 0) : Offset.zero,
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FC),
                    borderRadius: BorderRadius.circular(_isMenuOpen ? 26 : 0),
                    boxShadow: _isMenuOpen
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 26,
                              offset: const Offset(-2, 8),
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IgnorePointer(
                    ignoring: _isMenuOpen,
                    child: _buildHomeContent(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
