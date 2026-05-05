// =============================================================================
// Detalle de producto: foto, precio, colores, características, cantidad y carrito.
// Muestra información diferenciada según el rol del usuario.
// =============================================================================
import 'dart:ui' show ImageFilter;

import 'package:app_duralon/config/app_strings.dart';
import 'package:app_duralon/models/cart_item.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';
import 'package:app_duralon/pages/carrito_screen.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/services/locale_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/color_utils.dart';
import 'package:app_duralon/widgets/cart_added_toast.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:app_duralon/widgets/product_image.dart';
import 'package:flutter/material.dart';

// Mapa de nombre de color (español) → Color de Flutter para los chips.
const Map<String, Color> _kColorMap = {
  'Azul':         Color(0xFF1565C0),
  'Rojo':         Color(0xFFC62828),
  'Verde':        Color(0xFF2E7D32),
  'Amarillo':     Color(0xFFF9A825),
  'Naranja':      Color(0xFFE65100),
  'Rosado':       Color(0xFFEC407A),
  'Fucsia':       Color(0xFFAD1457),
  'Morado':       Color(0xFF6A1B9A),
  'Violeta':      Color(0xFF6A1B9A),
  'Negro':        Color(0xFF212121),
  'Blanco':       Color(0xFFF5F5F5),
  'Crema':        Color(0xFFF0DEB8),
  'Caramelo':     Color(0xFFC8860A),
  'Gris':         Color(0xFF757575),
  'Marrón':       Color(0xFF6D4C41),
  'Ladrillo':     Color(0xFFB71C1C),
  'Mostaza':      Color(0xFFF57F17),
  'Terracota':    Color(0xFFBF360C),
  'Verde Limón':  Color(0xFF8BC34A),
  'Menta':        Color(0xFF80CBC4),
  'Celeste':      Color(0xFF4FC3F7),
  'Clear':        Color(0xFFE0F7FA),
  'Transparente': Color(0xFFE0F7FA),
};

// =============================================================================
// Widget público
// =============================================================================
class ProductoScreen extends StatefulWidget {
  const ProductoScreen({
    super.key,
    required this.product,
    this.colorProducts,
    this.isGuestMode = false,
    this.userRole,
  });

  final Product product;

  /// Lista completa de variantes de color del mismo grupo (null si no hay grupo).
  final List<Product>? colorProducts;
  final bool isGuestMode;

  /// Rol del usuario: 'cliente_minorista', 'cliente_distribuidor',
  /// 'admin'. Nulo = invitado.
  final String? userRole;

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> {
  late int _empaques;
  final PageController _imagePageController = PageController();

  ProductVariant? _selectedVariant;
  String? _selectedColor;

  late Product _activeColorProduct;

  Product get _p => _activeColorProduct;

  int get _packQty {
    final qty = _selectedVariant?.packQty ?? _p.minOrderQty;
    return qty > 0 ? qty : 1;
  }

  int get _totalUnidades => _empaques * _packQty;

  double? get _cbmPerEmpaque {
    final dims = _selectedVariant?.dimensions.isNotEmpty == true
        ? _selectedVariant!.dimensions
        : _p.dimensions;
    final l = dims['largo'];
    final a = dims['ancho'];
    final h = dims['alto'];
    if (l == null || a == null || h == null) return null;
    return (l * a * h) / 1_000_000 * _packQty;
  }

  int get _effectiveMinOrderQty => 1;
  int get _stepQty => 1;

  double get _activePrice {
    if (_selectedVariant != null) {
      return _isDistribuidor
          ? _selectedVariant!.priceDistributor
          : _selectedVariant!.priceRetail;
    }
    return _p.price;
  }

  double get _total => _activePrice * _empaques;

  bool get _isDistribuidor =>
      widget.userRole == 'cliente_distribuidor' ||
      widget.userRole == 'admin';

  bool get _isAdmin => widget.userRole == 'admin';

  List<String> get _displayColors {
    if (_p.hasVariants) {
      final seen = <String>{};
      return _p.activeVariants
          .map((v) => v.color)
          .where((c) => seen.add(c))
          .toList();
    }
    return _p.parsedColors;
  }

  @override
  void initState() {
    super.initState();
    _activeColorProduct = widget.product;
    _empaques = 1;
    if (_displayColors.length == 1) {
      _selectedColor = _displayColors.first;
      if (_p.hasVariants && _p.activeVariants.isNotEmpty) {
        _selectedVariant = _p.activeVariants.firstWhere(
          (v) => v.color == _selectedColor,
          orElse: () => _p.activeVariants.first,
        );
      }
    }
  }

  void _onProductColorSelected(Product product) {
    if (product.id == _activeColorProduct.id) return;
    setState(() {
      _activeColorProduct = product;
      _empaques = 1;
      _selectedColor = null;
      _selectedVariant = null;
      // Auto-select if only one color variant
      if (_displayColors.length == 1) {
        _selectedColor = _displayColors.first;
        if (_p.hasVariants && _p.activeVariants.isNotEmpty) {
          _selectedVariant = _p.activeVariants.firstWhere(
            (v) => v.color == _selectedColor,
            orElse: () => _p.activeVariants.first,
          );
        }
      }
    });
    _imagePageController.jumpToPage(0);
  }

  void _onColorSelected(String color) {
    setState(() {
      if (_selectedColor == color) {
        _selectedColor = null;
        _selectedVariant = null;
      } else {
        _selectedColor = color;
        if (_p.hasVariants) {
          _selectedVariant = _p.activeVariants
              .firstWhere((v) => v.color == color, orElse: () => _p.activeVariants.first);
        }
      }
    });
  }

  void _onAnadirAlCarrito(BuildContext context) {
    if (widget.isGuestMode) {
      showDuralonGuestCartDialog(context);
      return;
    }
    final minQty = _effectiveMinOrderQty;
    if (_empaques < minQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.minQtyError}: $minQty ${minQty != 1 ? S.packagePlural : S.package}.')),
      );
      return;
    }
    if (_stepQty > 1 && (_empaques - minQty) % _stepQty != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.multipleError} $_stepQty ${S.packagePlural} ${S.from} $minQty.'),
        ),
      );
      return;
    }
    final item = CartItem.fromProduct(
      _p,
      _selectedVariant,
      _empaques,
      _isDistribuidor,
    );
    CartService.instance.addItem(item);
    showCartAddedToast(context, _p.name, _empaques);
  }

  Widget _buildPriceLocked(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF), size: 22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.loginToSeePrices,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            S.loginToAddCart,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                S.signIn,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _abrirFotoEnGrande(BuildContext context) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, a1, a2) =>
            _FotoProductoPantallaCompleta(imageSrc: _p.displayImage),
        transitionsBuilder: (ctx, animation, a2, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F7),
          body: SafeArea(
            child: Column(
              children: [
                // ── Barra superior ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                      ),
                      Expanded(
                        child: Text(
                          S.productTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: CartService.instance,
                        builder: (context, _) {
                          final count = CartService.instance.totalPiezas;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (widget.isGuestMode) {
                                    showDuralonGuestCartDialog(context);
                                  } else {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const CarritoScreen(),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                                tooltip: S.cartTooltip,
                              ),
                              if (count > 0)
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
                                        '$count',
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B2C),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                // ── Contenido con scroll ─────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // ── Foto ───────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                elevation: 0.5,
                                shadowColor: Colors.black26,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: AspectRatio(
                                    aspectRatio: 1.05,
                                    child: GestureDetector(
                                      onTap: () => _abrirFotoEnGrande(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: PageView(
                                        controller: _imagePageController,
                                        children: [
                                          _p.displayImage,
                                          ..._p.imageUrls,
                                        ]
                                            .map((src) => ProductImage(
                                                  src: src,
                                                  fit: BoxFit.contain,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.playlist_add, size: 22, color: Color(0xFF1E2A3A)),
                                    tooltip: S.addToList,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.favorite_border, size: 22, color: Color(0xFF1E2A3A)),
                                    tooltip: S.favorites,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.share_outlined, size: 22, color: Color(0xFF1E2A3A)),
                                    tooltip: S.share,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Ficha del producto ─────────────────────
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Precio + badge categoría
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!widget.isGuestMode)
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            _activePrice == 0
                                                ? S.priceConsult
                                                : 'RD\$ ${_activePrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize: _activePrice == 0 ? 16 : 22,
                                              fontWeight: FontWeight.w800,
                                              color: _activePrice == 0
                                                  ? const Color(0xFF8E9AAF)
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (_p.listPrice != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              'RD\$ ${_p.listPrice!.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF8E9AAF),
                                                decoration: TextDecoration.lineThrough,
                                                decorationColor: AppColors.primaryRed,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    const Expanded(child: SizedBox.shrink()),
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE5E8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _p.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Nombre
                              const SizedBox(height: 12),
                              Text(
                                _p.nameFor(LocaleService.instance.language.name),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),

                              // Código / EAN (solo admin)
                              if (_isAdmin) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _BadgeInfo(label: S.codeLabel, value: _p.id),
                                    if (_isAdmin && _p.ean?.isNotEmpty == true) ...[
                                      const SizedBox(width: 8),
                                      _BadgeInfo(label: S.eanLabel, value: _p.ean!),
                                    ],
                                  ],
                                ),
                              ],

                              // Descripción
                              if (_p.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _p.description!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4A5568),
                                    height: 1.5,
                                  ),
                                ),
                              ],

                              // ── Selector de producto por color ─────
                              if (widget.colorProducts != null &&
                                  widget.colorProducts!.length > 1) ...[
                                const SizedBox(height: 16),
                                _ProductColorSelector(
                                  products: widget.colorProducts!,
                                  activeProductId: _activeColorProduct.id,
                                  onSelect: _onProductColorSelected,
                                ),
                              ],

                              // ── Selector de color (variantes internas) ──
                              // Solo se muestra si hay múltiples colores seleccionables
                              // o es surtido. Si hay un _ProductColorSelector activo y
                              // el producto solo tiene un color, se omite (ya está cubierto).
                              if (_displayColors.length > 1 || _p.isSurtido) ...[
                                const SizedBox(height: 16),
                                _ColorSelector(
                                  displayColors: _displayColors,
                                  isSurtido: _p.isSurtido,
                                  selectedColor: _selectedColor,
                                  onColorSelected: _onColorSelected,
                                ),
                              ],

                              // ── Características del producto ───────
                              const SizedBox(height: 16),
                              _CaracteristicasCard(
                                product: _p,
                                selectedVariant: _selectedVariant,
                                isDistribuidor: _isDistribuidor,
                                isAdmin: _isAdmin,
                              ),

                              // Sección de compra: bloqueada para invitados
                              if (widget.isGuestMode) ...[
                                const SizedBox(height: 16),
                                _buildPriceLocked(context),
                              ] else ...[
                                // Compra mínima
                                const SizedBox(height: 12),
                                Text(
                                  '${S.minPurchase}: $_effectiveMinOrderQty ${_effectiveMinOrderQty != 1 ? S.packagePlural : S.package}'
                                  '${_stepQty > 1 ? '  |  ${S.multiple}: $_stepQty' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6A7482),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                // Selector de empaques
                                const SizedBox(height: 24),
                                Text(
                                  S.packages,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E9AAF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _QtyCircleButton(
                                      icon: Icons.remove,
                                      onPressed: _empaques > _effectiveMinOrderQty
                                          ? () => setState(() => _empaques -= _stepQty)
                                          : null,
                                      highlight: false,
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F2F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_empaques',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            _empaques != 1 ? S.packagePlural : S.package,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF8E9AAF),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _QtyCircleButton(
                                      icon: Icons.add,
                                      onPressed: _empaques + _stepQty <= 9999
                                          ? () => setState(() => _empaques += _stepQty)
                                          : null,
                                      highlight: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$_empaques ${_empaques != 1 ? S.packagePlural : S.package} = $_totalUnidades ${S.units}  ($_packQty und/emp)',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A7482),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_cbmPerEmpaque != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'CBM: ${(_cbmPerEmpaque! * _empaques).toStringAsFixed(4)} m³  (${_cbmPerEmpaque!.toStringAsFixed(4)} m³/${S.package})',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6A7482),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                if (_activePrice > 0)
                                  Text(
                                    '${S.total}: RD\$ ${_total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => _onAnadirAlCarrito(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      S.addToCart,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Selector de producto por color (grupo de colores)
// =============================================================================
const Map<String, Color> _kColorMapSelector = {
  'Azul':         Color(0xFF1565C0),
  'Rojo':         Color(0xFFC62828),
  'Verde':        Color(0xFF2E7D32),
  'Amarillo':     Color(0xFFF9A825),
  'Naranja':      Color(0xFFE65100),
  'Rosado':       Color(0xFFEC407A),
  'Fucsia':       Color(0xFFAD1457),
  'Morado':       Color(0xFF6A1B9A),
  'Violeta':      Color(0xFF6A1B9A),
  'Negro':        Color(0xFF212121),
  'Blanco':       Color(0xFFF5F5F5),
  'Crema':        Color(0xFFF0DEB8),
  'Caramelo':     Color(0xFFC8860A),
  'Gris':         Color(0xFF757575),
  'Marrón':       Color(0xFF6D4C41),
  'Ladrillo':     Color(0xFFB71C1C),
  'Mostaza':      Color(0xFFF57F17),
  'Terracota':    Color(0xFFBF360C),
  'Verde Limón':  Color(0xFF8BC34A),
  'Menta':        Color(0xFF80CBC4),
  'Celeste':      Color(0xFF4FC3F7),
  'Clear':        Color(0xFFE0F7FA),
  'Transparente': Color(0xFFE0F7FA),
};

class _ProductColorSelector extends StatelessWidget {
  const _ProductColorSelector({
    required this.products,
    required this.activeProductId,
    required this.onSelect,
  });

  final List<Product> products;
  final String activeProductId;
  final ValueChanged<Product> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.colorLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2A3A),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: products.map((p) {
            final colorName = p.color?.split('/').first.trim() ?? '';
            final isTransparent = isTransparentColor(colorName);
            final col = _kColorMapSelector[colorName] ?? const Color(0xFFB0B8C4);
            final isLight = (0.299 * col.r + 0.587 * col.g + 0.114 * col.b) / 255 > 0.7;
            final isSelected = p.id == activeProductId;

            return GestureDetector(
              onTap: () => onSelect(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isTransparent
                      ? (isSelected ? const Color(0xFFE0E0E0) : Colors.white)
                      : (isSelected ? col : col.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTransparent
                        ? const Color(0xFF757575)
                        : (isSelected ? col : col.withValues(alpha: 0.5)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: isTransparent
                              ? Colors.black26
                              : col.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTransparent)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF9E9E9E), width: 0.8),
                        ),
                        child: ClipOval(
                          child: CustomPaint(
                            size: const Size(14, 14),
                            painter: const ColorCheckerPainter(),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLight ? const Color(0xFFCCCCCC) : Colors.transparent,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      colorName.isNotEmpty ? colorName : p.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF374151),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

// =============================================================================
// Selector de color
// =============================================================================
class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.displayColors,
    required this.isSurtido,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<String> displayColors;
  final bool isSurtido;
  final String? selectedColor;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    if (!isSurtido && displayColors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.colorLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2A3A),
          ),
        ),
        const SizedBox(height: 8),
        if (isSurtido)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  S.surtido,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  S.colorNotSelectable,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayColors.map((color) {
              final isSelected = selectedColor == color;
              final isTransparent = isTransparentColor(color);
              final chipColor = _kColorMap[color] ?? const Color(0xFFB0B8C4);
              final isLight = _isLightColor(chipColor);
              final isSingle = displayColors.length == 1;

              return GestureDetector(
                onTap: isSingle ? null : () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTransparent
                        ? (isSelected ? const Color(0xFFE0E0E0) : Colors.white)
                        : (isSelected ? chipColor : chipColor.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTransparent
                          ? const Color(0xFF757575)
                          : (isSelected ? chipColor : chipColor.withValues(alpha: 0.5)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: isTransparent ? Colors.black26 : chipColor.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTransparent)
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF9E9E9E), width: 0.8),
                          ),
                          child: ClipOval(
                            child: CustomPaint(
                              size: const Size(14, 14),
                              painter: const ColorCheckerPainter(),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: chipColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLight ? const Color(0xFFCCCCCC) : Colors.transparent,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        color,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected && !isTransparent && !isLight
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isSelected && !isTransparent && !isLight
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  static bool _isLightColor(Color color) {
    final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.7;
  }
}

// =============================================================================
// Tarjeta de Características
// =============================================================================
class _CaracteristicasCard extends StatefulWidget {
  const _CaracteristicasCard({
    required this.product,
    this.selectedVariant,
    required this.isDistribuidor,
    required this.isAdmin,
  });

  final Product product;
  final ProductVariant? selectedVariant;
  final bool isDistribuidor;
  final bool isAdmin;

  @override
  State<_CaracteristicasCard> createState() => _CaracteristicasCardState();
}

class _CaracteristicasCardState extends State<_CaracteristicasCard> {
  bool _expanded = true;

  Product get _p => widget.product;
  ProductVariant? get _v => widget.selectedVariant;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      S.characteristics,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: rows,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];

    // 1. Código
    final codigo = _v?.codigo.isNotEmpty == true ? _v!.codigo : _p.id;
    if (codigo.isNotEmpty) {
      rows.add(_CaractRow(label: S.codeLabel, value: codigo));
    }

    // 2. Color
    final color = _v?.color.isNotEmpty == true && _v!.color != 'Sin color'
        ? _v!.color
        : _p.color;
    if (color != null && color.isNotEmpty) {
      rows.add(_CaractRow(label: S.colorLabel, value: color));
    }

    // 3. EAN
    final ean = _v?.ean.isNotEmpty == true ? _v!.ean : _p.ean;
    if (ean != null && ean.isNotEmpty) {
      rows.add(_CaractRow(label: S.eanLabel, value: ean));
    }

    // 4–6. Dimensiones individuales
    final dims = _v?.dimensions.isNotEmpty == true ? _v!.dimensions : _p.dimensions;
    if (dims['largo'] != null) {
      rows.add(_CaractRow(label: S.lengthLabel, value: _fmtDim(dims['largo']!)));
    }
    if (dims['ancho'] != null) {
      rows.add(_CaractRow(label: S.widthLabel, value: _fmtDim(dims['ancho']!)));
    }
    if (dims['alto'] != null) {
      rows.add(_CaractRow(label: S.heightLabel, value: _fmtDim(dims['alto']!)));
    }
    if (dims['peso'] != null) {
      rows.add(_CaractRow(label: S.weightLabel, value: '${dims['peso']!.toStringAsFixed(2)} kg'));
    }

    // CBM fijo por empaque
    final l = dims['largo'];
    final a = dims['ancho'];
    final h = dims['alto'];
    final pack = (_v?.packQty ?? _p.minOrderQty) > 0 ? (_v?.packQty ?? _p.minOrderQty) : 1;
    if (l != null && a != null && h != null) {
      final cbm = (l * a * h) / 1_000_000 * pack;
      rows.add(_CaractRow(label: S.cbmPerPack, value: '${cbm.toStringAsFixed(4)} m³'));
    }

    // 7. Empaque
    final packQty = _v?.packQty ?? _p.minOrderQty;
    if (packQty > 0) {
      rows.add(_CaractRow(label: S.packLabel, value: '$packQty'));
    }

    // 8. Total/Pallet
    final palletQty = _v?.palletQty ?? _p.palletQty;
    if (palletQty != null && palletQty > 0) {
      rows.add(_CaractRow(label: S.totalPallet, value: '$palletQty'));
    }

    // Precios por rol
    if (widget.isAdmin && _v != null) {
      rows.add(_CaractRow(
        label: S.priceRetail,
        value: 'RD\$ ${_v!.priceRetail.toStringAsFixed(0)}/paq',
        highlight: true,
      ));
      rows.add(_CaractRow(
        label: S.priceDistrib,
        value: 'RD\$ ${_v!.priceDistributor.toStringAsFixed(0)}/paq',
        highlight: true,
      ));
    } else if (widget.isDistribuidor && _v != null) {
      rows.add(_CaractRow(
        label: S.yourPrice,
        value: 'RD\$ ${_v!.priceDistributor.toStringAsFixed(0)}/paq',
        highlight: true,
      ));
    } else if (_v != null) {
      rows.add(_CaractRow(
        label: S.price,
        value: 'RD\$ ${_v!.priceRetail.toStringAsFixed(0)}/paq',
        highlight: true,
      ));
    }

    // Stock — solo admin
    if (widget.isAdmin && _v != null) {
      rows.add(_CaractRow(label: S.stock, value: '${_v!.stock} ${S.boxes}'));
    }

    return rows;
  }

  static String _fmtDim(double v) {
    final i = v.truncateToDouble();
    return i == v ? '${v.toInt()} cm' : '${v.toStringAsFixed(1)} cm';
  }
}

class _CaractRow extends StatelessWidget {
  const _CaractRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                color: highlight ? const Color(0xFF1E2A3A) : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Badge pequeño de info (código, EAN)
// =============================================================================
class _BadgeInfo extends StatelessWidget {
  const _BadgeInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Color(0xFF8E9AAF), fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF1E2A3A),
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Botón circular – / +
// =============================================================================
class _QtyCircleButton extends StatelessWidget {
  const _QtyCircleButton({
    required this.icon,
    required this.onPressed,
    required this.highlight,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: const Color(0xFFF0F2F6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: isDisabled
                ? const Color(0xFFB0B8C4)
                : (highlight ? AppColors.primaryRed : const Color(0xFF1E2A3A)),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Visor de foto en pantalla completa con efecto vidrio
// =============================================================================
class _FotoProductoPantallaCompleta extends StatelessWidget {
  const _FotoProductoPantallaCompleta({required this.imageSrc});
  final String imageSrc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 4.0,
                  child: ProductImage(src: imageSrc, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.white,
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                  icon: const Icon(Icons.close_rounded, size: 28),
                  tooltip: S.closePhoto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
