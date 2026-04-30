// =============================================================================
// Detalle de producto: foto, precio, colores, características, cantidad y carrito.
// Muestra información diferenciada según el rol del usuario.
// =============================================================================
import 'dart:ui' show ImageFilter;

import 'package:app_duralon/models/cart_item.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';
import 'package:app_duralon/pages/carrito_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/services/product_rules_service.dart';
import 'package:app_duralon/styles/app_style.dart';
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
    this.isGuestMode = false,
    this.userRole,
  });

  final Product product;
  final bool isGuestMode;

  /// Rol del usuario: 'cliente_minorista', 'cliente_distribuidor',
  /// 'admin'. Nulo = invitado.
  final String? userRole;

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> {
  late int _unidades;
  final PageController _imagePageController = PageController();
  final ProductRulesService _productRulesService = ProductRulesService();

  int? _remoteMinOrderQty;
  int? _remoteStepQty;

  /// Variante seleccionada (cuando hay variants con modelo completo).
  ProductVariant? _selectedVariant;

  /// Color seleccionado (nombre en español).
  String? _selectedColor;

  Product get _p => widget.product;

  int get _effectiveMinOrderQty =>
      _remoteMinOrderQty ?? (_p.minOrderQty > 0 ? _p.minOrderQty : 1);

  // Si stepQty no está definido, el paso = mínimo de paquete (no se puede
  // pedir fracción de paquete: si el mínimo es 20, los saltos son 20, 40, 60…).
  int get _stepQty {
    if (_remoteStepQty != null) return _remoteStepQty!;
    if (_p.stepQty > 0) return _p.stepQty;
    return _effectiveMinOrderQty;
  }

  double get _activePrice {
    if (_selectedVariant != null) {
      return _isDistribuidor
          ? _selectedVariant!.priceDistributor
          : _selectedVariant!.priceRetail;
    }
    return _p.price;
  }

  double get _total => _activePrice * _unidades;

  bool get _isDistribuidor =>
      widget.userRole == 'cliente_distribuidor' ||
      widget.userRole == 'admin';

  bool get _isAdmin => widget.userRole == 'admin';

  // ── Lista de colores que muestra el selector ──────────────────
  /// Si hay variantes activas usa sus colores únicos;
  /// si no, usa [Product.parsedColors].
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
    _unidades = _effectiveMinOrderQty;
    _loadWholesaleRules();
    // Auto-seleccionar si solo hay un color disponible.
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

  Future<void> _loadWholesaleRules() async {
    try {
      final rule = await _productRulesService.getRuleByProductId(_p.id);
      if (!mounted || rule == null) return;
      setState(() {
        _remoteMinOrderQty = rule.minOrderQty;
        _remoteStepQty = rule.stepQty;
        if (_unidades < _effectiveMinOrderQty) {
          _unidades = _effectiveMinOrderQty;
        }
      });
    } catch (_) {}
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
    if (_unidades < minQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cantidad mínima: $minQty unidades.')),
      );
      return;
    }
    if (_stepQty > 1 && (_unidades - minQty) % _stepQty != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compra en múltiplos de $_stepQty desde $minQty unidades.'),
        ),
      );
      return;
    }
    final item = CartItem.fromProduct(
      _p,
      _selectedVariant,
      _unidades,
      _isDistribuidor,
    );
    CartService.instance.addItem(item);
    showCartAddedToast(context, _p.name, _unidades);
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
                  const Expanded(
                    child: Text(
                      'Producto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                            tooltip: 'Carrito',
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
                                tooltip: 'Lista',
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
                                tooltip: 'Favoritos',
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
                                tooltip: 'Compartir',
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
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _activePrice == 0
                                          ? 'Precio a consultar'
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
                              ),
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
                            _p.name,
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
                                _BadgeInfo(label: 'Código', value: _p.id),
                                if (_isAdmin && _p.ean?.isNotEmpty == true) ...[
                                  const SizedBox(width: 8),
                                  _BadgeInfo(label: 'EAN', value: _p.ean!),
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

                          // ── Selector de color ──────────────────
                          const SizedBox(height: 16),
                          _ColorSelector(
                            displayColors: _displayColors,
                            isSurtido: _p.isSurtido,
                            selectedColor: _selectedColor,
                            onColorSelected: _onColorSelected,
                          ),

                          // ── Características del producto ───────
                          const SizedBox(height: 16),
                          _CaracteristicasCard(
                            product: _p,
                            selectedVariant: _selectedVariant,
                            isDistribuidor: _isDistribuidor,
                            isAdmin: _isAdmin,
                          ),

                          // Compra mínima
                          const SizedBox(height: 12),
                          Text(
                            'Compra mínima: $_effectiveMinOrderQty unidades'
                            '${_stepQty > 1 ? ' | Múltiplo: $_stepQty' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6A7482),
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          // Selector de cantidad
                          const SizedBox(height: 24),
                          const Text(
                            'Unidades',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                                onPressed: _unidades > _effectiveMinOrderQty
                                    ? () => setState(() => _unidades -= _stepQty)
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
                                child: Text(
                                  '$_unidades',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                              ),
                              _QtyCircleButton(
                                icon: Icons.add,
                                onPressed: _unidades + _stepQty <= 9999
                                    ? () => setState(() => _unidades += _stepQty)
                                    : null,
                                highlight: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_activePrice > 0)
                            Text(
                              'Total: RD\$ ${_total.toStringAsFixed(2)}',
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
                              child: const Text(
                                'Añadir al carrito',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
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
    // Sin información de color → no mostrar nada
    if (!isSurtido && displayColors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2A3A),
          ),
        ),
        const SizedBox(height: 8),
        if (isSurtido)
          // Producto surtido: no se puede elegir color individual
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
                const Text(
                  'Surtido',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(color no seleccionable)',
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
              final chipColor = _kColorMap[color] ?? const Color(0xFFB0B8C4);
              final isLight = _isLightColor(chipColor);
              final isSingle = displayColors.length == 1;

              return GestureDetector(
                onTap: isSingle ? null : () => onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : chipColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? chipColor : chipColor.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: chipColor.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          color: isSelected
                              ? (isLight ? const Color(0xFF374151) : Colors.white)
                              : const Color(0xFF374151),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isLight ? const Color(0xFF374151) : Colors.white,
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
          // Cabecera expandible
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Características',
                      style: TextStyle(
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

    // Dimensiones (de la variante si está seleccionada, si no del producto)
    final dims = _v?.dimensions.isNotEmpty == true ? _v!.dimensions : _p.dimensions;
    if (dims.isNotEmpty) {
      final parts = <String>[];
      if (dims['largo'] != null) parts.add('${dims['largo']!.toStringAsFixed(1)} cm largo');
      if (dims['ancho'] != null) parts.add('${dims['ancho']!.toStringAsFixed(1)} cm ancho');
      if (dims['alto']  != null) parts.add('${dims['alto']!.toStringAsFixed(1)} cm alto');
      if (dims['peso']  != null) parts.add('${dims['peso']!.toStringAsFixed(2)} kg');
      if (parts.isNotEmpty) {
        rows.add(_CaractRow(label: 'Dimensiones', value: parts.join(' × ')));
      }
    }

    // Empaque
    final packQty = _v?.packQty ?? _p.minOrderQty;
    if (packQty > 0) {
      rows.add(_CaractRow(label: 'Unidades/caja', value: '$packQty unidades'));
    }

    // Pallet
    final palletQty = _v?.palletQty ?? _p.palletQty;
    if (palletQty != null && palletQty > 0) {
      rows.add(_CaractRow(label: 'Cajas/pallet', value: '$palletQty cajas'));
    }

    // EAN de la variante (si está seleccionada) o del producto — solo admin
    final ean = _v?.ean.isNotEmpty == true ? _v!.ean : _p.ean;
    if (ean != null && ean.isNotEmpty && widget.isAdmin) {
      rows.add(_CaractRow(label: 'EAN', value: ean));
    }

    // Precios diferenciados por rol (sólo si hay variante seleccionada)
    if (widget.isAdmin && _v != null) {
      rows.add(_CaractRow(
        label: 'Precio minorista',
        value: 'RD\$ ${_v!.priceRetail.toStringAsFixed(0)}/caja',
        highlight: true,
      ));
      rows.add(_CaractRow(
        label: 'Precio distribuidor',
        value: 'RD\$ ${_v!.priceDistributor.toStringAsFixed(0)}/caja',
        highlight: true,
      ));
    } else if (widget.isDistribuidor && _v != null) {
      rows.add(_CaractRow(
        label: 'Tu precio',
        value: 'RD\$ ${_v!.priceDistributor.toStringAsFixed(0)}/caja',
        highlight: true,
      ));
    } else if (_v != null) {
      rows.add(_CaractRow(
        label: 'Precio',
        value: 'RD\$ ${_v!.priceRetail.toStringAsFixed(0)}/caja',
        highlight: true,
      ));
    }

    // Stock (sólo para ventas/admin)
    if (widget.isAdmin && _v != null) {
      rows.add(_CaractRow(label: 'Stock', value: '${_v!.stock} cajas disponibles'));
    }

    return rows;
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
                  tooltip: 'Cerrar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
