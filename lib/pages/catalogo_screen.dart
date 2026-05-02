// [CatalogoScreen]: contenido de la mitad deslizante en [HomeScreen] (no es el catalogo
// acordeon). [CatalogoStandaloneScreen] es otra ruta, pantalla completa con arbol.
import 'dart:async';

import 'package:app_duralon/data/catalog_category_icons.dart';
import 'package:app_duralon/models/catalog_category.dart';
import 'package:app_duralon/models/home_product_section.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/services/catalog_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/home/home_header.dart';
import 'package:app_duralon/widgets/home/horizontal_product_list.dart';
import 'package:app_duralon/widgets/home/main_categories_banner.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:app_duralon/widgets/home/home_side_menu.dart'
    show HomeSideMenu, kSideMenuItemsRequiringAccount;
import 'package:flutter/material.dart';

/// Home embebido: buscador, tabs Hogar/Industrial, banner y filas con carruseles.
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({
    super.key,
    required this.selectedStoreTab,
    required this.searchQuery,
    required this.productSections,
    required this.onMenuTap,
    required this.onCartTap,
    required this.onSearchChanged,
    required this.onStoreTabChanged,
    required this.onMainCategoriesTap,
    required this.onCategoryVerTodos,
    required this.onProductTap,
    required this.onAddToCart,
    this.streamError,
    this.onRetry,
    this.isGuestMode = false,
  });

  final int selectedStoreTab;
  final String searchQuery;
  final List<HomeProductSection> productSections;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onStoreTabChanged;
  /// Banner *Todas las categorias* (catalogo acordeon).
  final VoidCallback onMainCategoriesTap;
  final ValueChanged<HomeProductSection> onCategoryVerTodos;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onAddToCart;
  final String? streamError;
  final VoidCallback? onRetry;
  final bool isGuestMode;

  @override
  Widget build(BuildContext context) {
    const labels = ['HOGAR', 'INDUSTRIAL'];

    return CustomScrollView(
      slivers: [
        // Cabecera con menu, carrito y [TextField] de busqueda
        SliverToBoxAdapter(
          child: HomeHeader(
            onMenuTap: onMenuTap,
            onCartTap: onCartTap,
            onSearchChanged: onSearchChanged,
          ),
        ),
        // Pestañas HOGAR / INDUSTRIAL: cambia [productSections] en el [HomeScreen]
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Row(
              children: List.generate(labels.length, (index) {
                final isActive = selectedStoreTab == index;
                final activeColor = index == 1
                    ? AppColors.primaryBlue
                    : AppColors.primaryRed;
                return Expanded(
                  child: InkWell(
                    onTap: () => onStoreTabChanged(index),
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
                                  ? activeColor
                                  : const Color(0xFF74839B),
                              fontSize: 16,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 3,
                            width: 74,
                            decoration: BoxDecoration(
                              color: isActive ? activeColor : Colors.transparent,
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
            ),
        ),
        // Cinta "Todas las categorias" -> abre [CatalogoStandaloneScreen]
        SliverToBoxAdapter(
          child: MainCategoriesBanner(onTap: onMainCategoriesTap),
        ),
        if (searchQuery.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                'Resultados para "${searchQuery.trim()}"',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF5C6B82),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        if (productSections.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      streamError != null
                          ? Icons.cloud_off
                          : (searchQuery.trim().isNotEmpty
                              ? Icons.search_off
                              : Icons.inventory_2_outlined),
                      size: 56,
                      color: const Color(0xFF9AA8BD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      streamError != null
                          ? 'No se pudieron cargar los productos.'
                          : (searchQuery.trim().isNotEmpty
                              ? 'No se encontraron productos con esa búsqueda.'
                              : 'No hay productos disponibles en este tab.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5C6B82),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (streamError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        streamError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF9AA8BD),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (onRetry != null)
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reintentar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          ..._categorySlivers(context),
      ],
    );
  }

  // Una categoria = titulo + "Ver todos" + [HorizontalProductList].
  List<Widget> _categorySlivers(BuildContext context) {
    return productSections
        .map(
          (section) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila titulo categoria y boton listado completo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          iconForCatalogGroup(section.title),
                          size: 26,
                          color: const Color(0xFF262E3A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        FilledButton(
                          onPressed: () => onCategoryVerTodos(section),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lightBlue,
                            foregroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Ver todos',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HorizontalProductList(
                    products: section.previewProducts,
                    onAddToCart: onAddToCart,
                    onProductTap: onProductTap,
                    isGuestMode: isGuestMode,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}

// Pantalla aparte inspirada en tu referencia.
class CatalogoStandaloneScreen extends StatefulWidget {
  const CatalogoStandaloneScreen({
    super.key,
    this.isGuestMode = true,
    required this.onCartTap,
    required this.onSectionTap,
  });

  final bool isGuestMode;
  final VoidCallback onCartTap;
  final void Function(String catalogId, String subtype) onSectionTap;

  @override
  State<CatalogoStandaloneScreen> createState() =>
      _CatalogoStandaloneScreenState();
}

class _CatalogoStandaloneScreenState
    extends State<CatalogoStandaloneScreen> {
  bool _isMenuOpen = false;
  int _selectedTab = 0;
  String _searchQuery = '';
  String? _expandedCategory;

  List<CatalogCategory> _catalogs = const [];
  bool _catalogsLoaded = false;
  StreamSubscription<List<CatalogCategory>>? _catalogsSub;

  @override
  void initState() {
    super.initState();
    _catalogsSub = CatalogService.streamAll().listen(
      (cats) {
        if (!mounted) return;
        setState(() {
          _catalogs = cats;
          _catalogsLoaded = true;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _catalogsLoaded = true);
      },
    );
  }

  @override
  void dispose() {
    _catalogsSub?.cancel();
    super.dispose();
  }

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  void _closeMenu() {
    if (_isMenuOpen) setState(() => _isMenuOpen = false);
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponible pronto.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final tab = _selectedTab == 0 ? 'hogar' : 'industrial';

    final filteredCategories = _catalogs.where((cat) {
      if (cat.tab != tab) return false;
      if (query.isEmpty) return true;
      final categoryMatch = cat.title.toLowerCase().contains(query);
      final subtypeMatch =
          cat.subtypes.any((s) => s.toLowerCase().contains(query));
      return categoryMatch || subtypeMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Stack(
          children: [
            HomeSideMenu(
              selectedItem: 'Catalogo',
              onItemTap: (item) {
                if (item == 'Inicio') {
                  Navigator.of(context).maybePop();
                  return;
                }
                if (item == 'Catalogo') {
                  _closeMenu();
                  return;
                }
                if (widget.isGuestMode && kSideMenuItemsRequiringAccount.contains(item)) {
                  _closeMenu();
                  showDuralonGuestCartDialog(context);
                  return;
                }
                _closeMenu();
                _showComingSoon(item);
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
              offset: _isMenuOpen ? const Offset(0.72, 0) : Offset.zero,
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F7),
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
                  child: Column(
                    children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Catálogo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 35 / 2, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCartTap,
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColors.primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(2, (index) {
                final active = _selectedTab == index;
                final title = index == 0 ? 'HOGAR' : 'INDUSTRIAL';
                final activeColor = index == 1
                    ? AppColors.primaryBlue
                    : AppColors.primaryRed;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = index),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 28 / 2,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? activeColor
                                  : const Color(0xFF1F2733),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 3,
                          color: active ? activeColor : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Filtrar por nombre de sección...',
                  hintStyle: const TextStyle(color: Color(0xFFA5ADBA)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA5ADBA)),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!_catalogsLoaded)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryBlue),
                ),
              )
            else if (filteredCategories.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay categorías disponibles.\n'
                      'Un administrador debe cargarlas desde el Panel de administración.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF8A94A6), fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                  itemBuilder: (_, i) {
                    final cat = filteredCategories[i];
                    final isExpanded = _expandedCategory == cat.id;
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _expandedCategory =
                                    isExpanded ? null : cat.id;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    iconForCatalogGroup(cat.title),
                                    size: 28,
                                    color: const Color(0xFF262E3A),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      cat.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primaryRed,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 0, 14, 12),
                              child: Column(
                                children: cat.subtypes.map((subtype) {
                                  return ListTile(
                                    dense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8),
                                    leading: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.primaryRed,
                                    ),
                                    title: Text(subtype),
                                    onTap: () =>
                                        widget.onSectionTap(cat.id, subtype),
                                  );
                                }).toList(),
                              ),
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: filteredCategories.length,
                ),
              ),
                    ],
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
