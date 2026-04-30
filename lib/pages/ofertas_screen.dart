import 'package:app_duralon/models/cart_item.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/producto_screen.dart';
import 'package:app_duralon/services/cart_service.dart';
import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:flutter/material.dart';

class OfertasScreen extends StatelessWidget {
  const OfertasScreen({
    super.key,
    this.isGuestMode = false,
    this.userRole,
  });

  final bool isGuestMode;
  final String? userRole;

  bool get _isDistribuidor =>
      userRole == 'cliente_distribuidor' ||
      userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ofertas',
          style: TextStyle(color: Color(0xFF1A2230), fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService.streamAll(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final ofertas = (snap.data ?? [])
              .where((p) => p.listPrice != null && p.listPrice! > p.price && p.price > 0)
              .toList()
            ..sort((a, b) => _descuento(b).compareTo(_descuento(a)));

          if (ofertas.isEmpty) {
            return _buildEmpty();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.primaryRed),
                            const SizedBox(width: 6),
                            Text(
                              '${ofertas.length} productos en oferta',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _OfertaCard(
                      product: ofertas[i],
                      isDistribuidor: _isDistribuidor,
                      onTap: () => Navigator.push<void>(
                        context,
                        slideRightRoute<void>(ProductoScreen(
                          product: ofertas[i],
                          isGuestMode: isGuestMode,
                          userRole: userRole,
                        )),
                      ),
                      onAddToCart: () => _addToCart(context, ofertas[i]),
                    ),
                    childCount: ofertas.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    if (isGuestMode) {
      showDuralonGuestCartDialog(context);
      return;
    }
    final item = CartItem.fromProduct(
      product,
      product.activeVariants.isNotEmpty ? product.activeVariants.first : null,
      product.minOrderQty > 0 ? product.minOrderQty : 1,
      _isDistribuidor,
    );
    CartService.instance.addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} agregado al carrito')),
    );
  }

  int _descuento(Product p) {
    if (p.listPrice == null || p.listPrice! <= 0) return 0;
    return (((p.listPrice! - p.price) / p.listPrice!) * 100).round();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No hay ofertas disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pronto publicaremos promociones especiales',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de oferta ──────────────────────────────────────────────────────────

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    required this.product,
    required this.isDistribuidor,
    required this.onTap,
    required this.onAddToCart,
  });

  final Product product;
  final bool isDistribuidor;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  int get _pct {
    if (product.listPrice == null || product.listPrice! <= 0) return 0;
    return (((product.listPrice! - product.price) / product.listPrice!) * 100).round();
  }

  String _fmt(double n) =>
      'RD\$${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + badge descuento
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '-$_pct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    // Precio tachado
                    Text(
                      _fmt(product.listPrice!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    // Precio oferta
                    Text(
                      _fmt(product.price),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const Spacer(),
                    // Botón agregar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Agregar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _placeholder() => Container(
        height: 130,
        width: double.infinity,
        color: AppColors.lightBlue,
        child: Center(
          child: Image.asset('assets/images/duralon_logo.png', width: 48, height: 48, fit: BoxFit.contain),
        ),
      );
}
