// =============================================================================
// Pantalla de inicio: menu lateral, tabs HOGAR/INDUSTRIAL, secciones por
// categoria con carruseles de productos, busqueda y navegacion a catalogo,
// listado de productos y detalle (ProductoScreen).
// Usa Firebase Firestore en tiempo real para TODOS los usuarios (invitado y
// autenticado). Los archivos mock se conservan solo para pruebas locales.
// =============================================================================
import 'dart:async';
import 'dart:math' as math;

import 'package:app_duralon/models/catalog_category.dart';
import 'package:app_duralon/models/home_product_section.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/admin_panel_screen.dart';
import 'package:app_duralon/pages/admin_wholesale_rules_screen.dart';
import 'package:app_duralon/pages/perfil_screen.dart';
import 'package:app_duralon/pages/catalogo_screen.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/pages/producto_screen.dart';
import 'package:app_duralon/pages/productos_screen.dart';
import 'package:app_duralon/services/catalog_service.dart';
import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/models/cart_item.dart';
import 'package:app_duralon/pages/carrito_screen.dart';
import 'package:app_duralon/pages/mis_pedidos_screen.dart';
import 'package:app_duralon/pages/mis_direcciones_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:app_duralon/widgets/home/home_side_menu.dart'
    show HomeSideMenu, kSideMenuDrawerWidth, kSideMenuItemsRequiringAccount;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Raiz de la app: [isGuestMode] indica invitado (sin login).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.isGuestMode, this.userName});

  final bool isGuestMode;
  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;
  String _searchQuery = '';
  int _selectedStoreTab = 0;
  bool _canManageWholesaleRules = false;
  bool _isAdmin = false;
  String? _userRole;

  // ── Datos de Firebase ────────────────────────────────────────────────────────
  List<Product> _products = const [];
  List<CatalogCategory> _catalogs = const [];
  bool _productsLoaded = false;
  bool _catalogsLoaded = false;

  StreamSubscription<List<Product>>? _productsSub;
  StreamSubscription<List<CatalogCategory>>? _catalogsSub;

  bool get _isLoading => !_productsLoaded || !_catalogsLoaded;

  @override
  void initState() {
    super.initState();
    _loadRolePermissions();
    _startProductsStream();
    _startCatalogsStream();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _catalogsSub?.cancel();
    super.dispose();
  }

  // ── Permisos de rol (solo usuarios autenticados) ──────────────────────────────
  Future<void> _loadRolePermissions() async {
    if (widget.isGuestMode) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = doc.data()?['rol'] as String?;
      if (!mounted) return;
      setState(() {
        _userRole = role;
        _canManageWholesaleRules = role == 'admin' || role == 'vendedor';
        _isAdmin = role == 'admin';
      });
    } catch (_) {}
  }

  // ── Streams de Firebase ───────────────────────────────────────────────────────

  void _startProductsStream() {
    _productsSub = ProductService.streamAll().listen(
      (products) {
        if (!mounted) return;
        setState(() {
          _products = products;
          _productsLoaded = true;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _productsLoaded = true);
      },
    );
  }

  void _startCatalogsStream() {
    _catalogsSub = CatalogService.streamAll().listen(
      (cats) {
        if (!mounted) return;
        setState(() {
          _catalogs = cats;
          _catalogsLoaded = true;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _catalogsLoaded = true);
      },
    );
  }

  // ── Secciones del home ────────────────────────────────────────────────────────

  /// Categorías del tab activo (hogar | industrial) desde Firebase.
  List<CatalogCategory> get _activeCatalogs {
    final tab = _selectedStoreTab == 0 ? 'hogar' : 'industrial';
    return _catalogs.where((c) => c.tab == tab).toList();
  }

  /// Construye las secciones del home a partir de los catálogos y productos de Firebase.
  List<HomeProductSection> get _homeProductSections {
    final q = _searchQuery.trim().toLowerCase();
    return _activeCatalogs
        .map((cat) {
          var list = _productsForCatalog(cat);
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
            categoryId: cat.id,
            title: cat.title,
            subtypes: cat.subtypes,
            previewProducts: list,
          );
        })
        .where((s) => s.previewProducts.isNotEmpty)
        .toList();
  }

  /// Productos que pertenecen a una categoría del catálogo.
  /// Prioriza el campo [catalogId]; si no existe usa matching por subtipos.
  List<Product> _productsForCatalog(CatalogCategory cat) {
    final byId = _products.where((p) => p.catalogId == cat.id).toList();
    if (byId.isNotEmpty) return byId;
    final subtypeSet = cat.subtypes.map((s) => s.toLowerCase()).toSet();
    return _products
        .where((p) => subtypeSet.contains(p.category.toLowerCase()))
        .toList();
  }

  /// Productos de un subtipo específico (para el acordeón del catálogo).
  List<Product> _productsForSection(String section) {
    final key = section.trim().toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(key) ||
          p.category.toLowerCase().contains(key);
    }).toList();
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  void _closeMenu() {
    if (_isMenuOpen) setState(() => _isMenuOpen = false);
  }

  void _handleCartTap(BuildContext context, Product? product) {
    if (widget.isGuestMode) {
      showDuralonGuestCartDialog(context);
      return;
    }
    if (product != null) {
      final item = CartItem.fromProduct(
        product,
        product.activeVariants.isNotEmpty
            ? product.activeVariants.first
            : null,
        product.minOrderQty > 0 ? product.minOrderQty : 1,
        _isDistribuidor,
      );
      CartService.instance.addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} agregado al carrito')),
      );
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const CarritoScreen()),
      );
    }
  }

  bool get _isDistribuidor =>
      _userRole == 'cliente_distribuidor' ||
      _userRole == 'vendedor' ||
      _userRole == 'admin';

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponible pronto.')),
    );
  }

  // ── Navegación ────────────────────────────────────────────────────────────────

  void _openProductsScreen(BuildContext context, String section) {
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductosScreen(
          sectionTitle: section,
          products: _productsForSection(section),
          isGuestMode: widget.isGuestMode,
          userRole: _userRole,
        ),
      ),
    );
  }

  void _openProductosScreenForCategory(
    BuildContext context,
    HomeProductSection section,
  ) {
    final cat = _catalogs.firstWhere(
      (c) => c.id == section.categoryId,
      orElse: () => CatalogCategory(
        id: section.categoryId,
        title: section.title,
        tab: 'hogar',
        order: 0,
        subtypes: section.subtypes,
      ),
    );
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductosScreen(
          sectionTitle: section.title,
          products: _productsForCatalog(cat),
          isGuestMode: widget.isGuestMode,
          userRole: _userRole,
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
          userRole: _userRole,
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

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final drawerW = math.min(kSideMenuDrawerWidth, maxW);
            final slideX = maxW > 0 ? (drawerW / maxW).clamp(0.0, 1.0) : 0.0;

            return Stack(
              children: [
                HomeSideMenu(
                  selectedItem: 'Inicio',
                  showWholesaleRules: _canManageWholesaleRules,
                  showAdminPanel: _isAdmin,
                  onItemTap: (item) {
                    if (item == 'Inicio') {
                      _closeMenu();
                      return;
                    }
                    if (item == 'Mi perfil') {
                      _closeMenu();
                      if (widget.isGuestMode) {
                        showDuralonGuestCartDialog(context);
                        return;
                      }
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const PerfilScreen()),
                      );
                      return;
                    }
                    if (item == 'Catalogo') {
                      _closeMenu();
                      _openCatalogScreen(context);
                      return;
                    }
                    if (item == 'Panel de administración') {
                      _closeMenu();
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const AdminPanelScreen()),
                      );
                      return;
                    }
                    if (item == 'Mis pedidos') {
                      _closeMenu();
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const MisPedidosScreen()),
                      );
                      return;
                    }
                    if (item == 'Mis direcciones') {
                      _closeMenu();
                      if (widget.isGuestMode) {
                        showDuralonGuestCartDialog(context);
                        return;
                      }
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const MisDireccionesScreen()),
                      );
                      return;
                    }
                    if (item == 'Reglas mayoristas') {
                      _closeMenu();
                      if (!_canManageWholesaleRules) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No tienes permisos para reglas mayoristas.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(
                          const AdminWholesaleRulesScreen(),
                        ),
                      );
                      return;
                    }
                    if (widget.isGuestMode &&
                        kSideMenuItemsRequiringAccount.contains(item)) {
                      _closeMenu();
                      showDuralonGuestCartDialog(context);
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
                AnimatedSlide(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  offset: _isMenuOpen ? Offset(slideX, 0) : Offset.zero,
                  child: GestureDetector(
                    onTap: _closeMenu,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(
                          _isMenuOpen ? 26 : 0,
                        ),
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
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : CatalogoScreen(
                                selectedStoreTab: _selectedStoreTab,
                                searchQuery: _searchQuery,
                                productSections: _homeProductSections,
                                onMenuTap: _toggleMenu,
                                onCartTap: () => _handleCartTap(context, null),
                                onSearchChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                onStoreTabChanged: (i) =>
                                    setState(() => _selectedStoreTab = i),
                                onMainCategoriesTap: () =>
                                    _openCatalogScreen(context),
                                onCategoryVerTodos: (section) =>
                                    _openProductosScreenForCategory(
                                      context,
                                      section,
                                    ),
                                onProductTap: (p) =>
                                    _openProductoScreen(context, p),
                                onAddToCart: (p) => _handleCartTap(context, p),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
