// Carrusel horizontal: tocar imagen+nombre abre detalle. El carrito está fuera del
// [InkWell] del detalle para que siempre dispare [onAddToCart] (invitado → diálogo).
import 'package:app_duralon/config/app_locale.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/widgets/product_image.dart';
import 'package:flutter/material.dart';

class HorizontalProductList extends StatelessWidget {
  const HorizontalProductList({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Altura fija para alinear filas de categorias en el home.
    return SizedBox(
      height: 258,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: products.length,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 176,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => onProductTap(product),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 112,
                              width: double.infinity,
                              color: Colors.white,
                              padding: const EdgeInsets.all(8),
                              child: ProductImage(
                                src: product.displayImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            product.nameFor(LocaleScope.lang(context)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RD\$ ${product.price.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onAddToCart(product),
                          icon: const Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 20,
                            color: AppColors.primaryRed,
                          ),
                          tooltip: 'Agregar al carrito',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
