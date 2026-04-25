// =============================================================================
// Detalle de un producto: foto, precio, categoria, cantidad y añadir al carrito.
// Al tocar la imagen se abre un visor a pantalla completa con fondo vidrio
// (desenfoque + tinte). El mock usa [Product]; con backend basta mapear el JSON
// a ese modelo (o reemplazar la fuente de datos en esta pantalla).
// =============================================================================
import 'dart:ui' show ImageFilter;

import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/services/product_rules_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// [ProductoScreen] — Widget publico. Recibe el [Product] y si el usuario es invitado
// (no puede comprar hasta iniciar sesion).
// -----------------------------------------------------------------------------
class ProductoScreen extends StatefulWidget {
  const ProductoScreen({
    super.key,
    required this.product,
    this.isGuestMode = false,
  });

  final Product product;
  final bool isGuestMode;

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> {
  // --- Estado: cantidad a comprar y carrusel de imagenes (hoy 1 sola) ---
  late int _unidades;
  final PageController _imagePageController = PageController();
  final ProductRulesService _productRulesService = ProductRulesService();
  int? _remoteMinOrderQty;
  int? _remoteStepQty;

  Product get _p => widget.product;
  int get _effectiveMinOrderQty =>
      _remoteMinOrderQty ?? (_p.minOrderQty > 0 ? _p.minOrderQty : 1);

  /// Precio total = precio unitario * unidades.
  double get _total => _p.price * _unidades;
  int get _stepQty => _remoteStepQty ?? (_p.stepQty <= 0 ? 1 : _p.stepQty);

  @override
  void initState() {
    super.initState();
    _unidades = _effectiveMinOrderQty;
    _loadWholesaleRules();
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
    } catch (_) {
      // Si no hay permisos/regla remota, usamos valores locales del modelo.
    }
  }

  // ---------------------------------------------------------------------------
  // Carrito: invitados no pueden "comprar"; se muestra un aviso.
  // ---------------------------------------------------------------------------
  void _avisoNecesitaCuenta(BuildContext context) {
    showDuralonGuestCartDialog(context);
  }

  void _onAnadirAlCarrito(BuildContext context) {
    if (widget.isGuestMode) {
      _avisoNecesitaCuenta(context);
      return;
    }
    final minQty = _effectiveMinOrderQty;
    if (_unidades < minQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cantidad minima: $minQty unidades.'),
        ),
      );
      return;
    }
    final usesStepRule = _stepQty > 1;
    if (usesStepRule && (_unidades - minQty) % _stepQty != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compra en multiplos de $_stepQty desde $minQty unidades.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_p.name} (x$_unidades) anadido al carrito.'),
      ),
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Visor de foto grande: ruta no opaca + barrera transparente; el blur esta
  // dentro de [_FotoProductoPantallaCompleta].
  // ---------------------------------------------------------------------------
  void _abrirFotoEnGrande(BuildContext context) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FotoProductoPantallaCompleta(imageAsset: _p.imageAsset);
        },
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // Barra superior: volver, titulo, icono carrito (placeholder).
            // -----------------------------------------------------------------
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
                  IconButton(
                    onPressed: () {
                      if (widget.isGuestMode) {
                        showDuralonGuestCartDialog(context);
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    tooltip: 'Carrito',
                  ),
                ],
              ),
            ),
            // Acento decorativo bajo el titulo (naranja).
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B2C),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // -----------------------------------------------------------------
            // Contenido con scroll: imagen, indicador, ficha (precio, CTA, etc.)
            // -----------------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // --- Foto: tap abre el visor; encima iconos flotantes (listas, etc.) ---
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
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                    bottom: Radius.zero,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1.05,
                                    child: GestureDetector(
                                      onTap: () => _abrirFotoEnGrande(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: PageView(
                                        controller: _imagePageController,
                                        children: [
                                          Image.asset(
                                            _p.imageAsset,
                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                                icon: const Icon(
                                  Icons.playlist_add,
                                  size: 22,
                                  color: Color(0xFF1E2A3A),
                                ),
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
                                icon: const Icon(
                                  Icons.favorite_border,
                                  size: 22,
                                  color: Color(0xFF1E2A3A),
                                ),
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
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 22,
                                  color: Color(0xFF1E2A3A),
                                ),
                                tooltip: 'Compartir',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Indicador estilo galeria (hoy 1 sola diapositiva; si añades
                    // mas imagenes a [PageView], actualiza con PageController).
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
                    // --- Ficha: precio, categoria, nombre, unidades, total, boton ---
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Fila 1: precio actual, precio tachado opcional, badge categoria
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      'RD\$ ${_p.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
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
                          // Nombre comercial (viene de [Product.name]).
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
                          const SizedBox(height: 8),
                          Text(
                            'Compra minima: $_effectiveMinOrderQty unidades'
                            '${_stepQty > 1 ? ' | Multiplo: $_stepQty' : ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6A7482),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Selector de cantidad [1..99] y total calculado.
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F2F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unidades',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _QtyCircleButton(
                                icon: Icons.add,
                                onPressed: _unidades + _stepQty <= 999
                                    ? () => setState(() => _unidades += _stepQty)
                                    : null,
                                highlight: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                          // CTA: aqui conectarias envio al carrito real o API.
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
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

// -----------------------------------------------------------------------------
// Boton circular - / + para unidades. [highlight] pinta + en rojo (marca).
// -----------------------------------------------------------------------------
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
// Vista modal de imagen: detras se ve la pantalla anterior borrosa (vidrio)
// gracias a [BackdropFilter]. [InteractiveViewer] permite zoom con pellizco.
// Se cierra con el boton X o el gesto atras del sistema.
// =============================================================================
class _FotoProductoPantallaCompleta extends StatelessWidget {
  const _FotoProductoPantallaCompleta({required this.imageAsset});

  final String imageAsset;

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
              // Capa 1: desenfoca + tinte claro = efecto cristal / vitral.
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
              // Capa 2: imagen nítida, zoom libre.
              Center(
                child: InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 4.0,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Capa 3: cerrar.
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                  ),
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
