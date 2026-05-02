import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/widgets/product_image.dart';
import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onBuyNow,
    this.isGuestMode = false,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onBuyNow;
  final bool isGuestMode;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ProductCard(
            product: products[index],
            isGuestMode: isGuestMode,
            onAddToCart: () => onAddToCart(products[index]),
            onBuyNow: () => onBuyNow(products[index]),
          ),
          childCount: products.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onBuyNow,
    this.isGuestMode = false,
  });

  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool isGuestMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: ProductImage(src: product.displayImage, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.category,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF5C6B82),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            if (isGuestMode)
              Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFB0B8C4)),
                  const SizedBox(width: 4),
                  Text(
                    'Inicia sesión',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB0B8C4),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              )
            else
              Text(
                'RD\$ ${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            const SizedBox(height: 8),
            if (!isGuestMode)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAddToCart,
                      child: const Text('Carrito'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onBuyNow,
                      child: const Text('Comprar'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
