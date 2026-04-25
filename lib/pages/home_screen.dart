// =============================================================================
// Pantalla de inicio: menu lateral, tabs HOGAR/INDUSTRIAL, secciones por
// categoria con carruseles de productos, busqueda y navegacion a catalogo,
// listado de productos y detalle (ProductoScreen).
// =============================================================================
import 'package:app_duralon/config/app_config.dart';
import 'package:app_duralon/data/catalog_category_tree.dart';
import 'package:app_duralon/data/home_category_products_source.dart';
import 'package:app_duralon/data/mock_products.dart';
import 'package:app_duralon/models/home_product_section.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/catalogo_screen.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/pages/producto_screen.dart';
import 'package:app_duralon/pages/productos_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:app_duralon/widgets/home/home_side_menu.dart';
import 'package:flutter/material.dart';

/// Raiz de la app: [isGuestMode] indica invitado (sin login). Con backend, suele
/// ser `!auth.isLoggedIn`. Para **cuenta de prueba vs real** en el servidor, usa
/// [UserAccountType] en el perfil, no solo este bool.
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
  // --- Menu lateral, texto del buscador, tab 0=Hogar 1=Industrial ---
  bool _isMenuOpen = false;
  String _searchQuery = '';
  int _selectedStoreTab = 0;

  // ---------------------------------------------------------------------------
  // UI: apertura/cierre del drawer y toques fuera.
  // ---------------------------------------------------------------------------
  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
    }
  }

  void _handleCartTap(BuildContext context, Product? product) {
    if (widget.isGuestMode) {
      showDuralonGuestCartDialog(context);
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

  // ---------------------------------------------------------------------------
  // Construye las filas del home: por cada categoria (Cocina, etc.) lista de
  // productos del mock, filtrada por busqueda si el usuario escribio en el header.
  // ---------------------------------------------------------------------------
  List<HomeProductSection> get _homeProductSections {
    final map = _selectedStoreTab == 0 ? kCatalogHogar : kCatalogIndustrial;
    final q = _searchQuery.trim().toLowerCase();
    return map.entries
        .map((e) {
          var list = productsForHomeCategoryPreview(e.key, e.value);
          if (q.isNotEmpty) {
            list = list
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(q) ||
                      p.category.toLowerCase().contains(q),
                )
                .toList();
          }
          return HomeProductSection(
            categoryId: kCatalogGroupIdByTitle[e.key]!,
            title: e.key,
            subtypes: e.value,
            previewProducts: list,
          );
        })
        .where((s) => s.previewProducts.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Productos que coinciden con un "subtipo" al abrirlo desde el catalogo
  // con acordeones (por nombre o categoria contiene [section]).
  // ---------------------------------------------------------------------------
  /// Listado al abrir un subtipo desde el catalogo acordeon. Mock solo en demo.
  List<Product> _productsForSection(String section) {
    if (!AppConfig.useMockCatalog) {
      // TODO(Backend): buscar productos por slug de subtipo
      return const <Product>[];
    }
    final key = section.trim().toLowerCase();
    return mockProducts.where((product) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      return name.contains(key) || category.contains(key);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Navegacion: listados y detalle; todas usan [slideRightRoute] (gesto atras iOS).
  // ---------------------------------------------------------------------------
  void _openProductsScreen(BuildContext context, String section) {
    final sectionProducts = _productsForSection(section);
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductosScreen(
          sectionTitle: section,
          products: sectionProducts,
          isGuestMode: widget.isGuestMode,
        ),
      ),
    );
  }

  void _openProductosScreenForCategory(BuildContext context, HomeProductSection section) {
    final allInCategory = productsForFullCategoryList(section);
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductosScreen(
          sectionTitle: section.title,
          products: allInCategory,
          isGuestMode: widget.isGuestMode,
        ),
      ),
    );
  }

  void _openProductoScreen(BuildContext context, Product product) {
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductoScreen(
          product: product,
          isGuestMode: widget.isGuestMode,
        ),
      ),
    );
  }

  void _openCatalogScreen(BuildContext context) {
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        CatalogoStandaloneScreen(
          isGuestMode: widget.isGuestMode,
          onCartTap: () => _handleCartTap(context, null),
          onSectionTap: (section) => _openProductsScreen(context, section),
        ),
      ),
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
              selectedItem: 'Inicio',
              onItemTap: (item) {
                if (item == 'Inicio') {
                  _closeMenu();
                  return;
                }
                if (item == 'Catalogo') {
                  _closeMenu();
                  _openCatalogScreen(context);
                  return;
                }
                if (item == 'Mi perfil') {
                  _closeMenu();
                  if (widget.isGuestMode) {
                    showDuralonGuestCartDialog(context);
                  } else {
                    _showComingSoon(context, item);
                  }
                  return;
                }
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
            // --- Contenedor principal: [CatalogoScreen] = header + tabs + secciones ---
            AnimatedSlide(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              offset: _isMenuOpen ? const Offset(0.72, 0) : Offset.zero,
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
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
                    child: CatalogoScreen(
                      selectedStoreTab: _selectedStoreTab,
                      searchQuery: _searchQuery,
                      productSections: _homeProductSections,
                      onMenuTap: _toggleMenu,
                      onCartTap: () => _handleCartTap(context, null),
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onStoreTabChanged: (tabIndex) =>
                          setState(() => _selectedStoreTab = tabIndex),
                      onMainCategoriesTap: () => _openCatalogScreen(context),
                      onCategoryVerTodos: (section) =>
                          _openProductosScreenForCategory(context, section),
                      onProductTap: (product) => _openProductoScreen(context, product),
                      onAddToCart: (product) => _handleCartTap(context, product),
                    ),
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
