// Carrusel horizontal: productos agrupados por código base (variantes de color).
// Un grupo con varios colores muestra dots de color. El tap abre ProductoScreen
// con la lista completa de variantes para que el usuario elija en el detalle.
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/services/locale_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/color_utils.dart';
import 'package:app_duralon/widgets/product_image.dart';
import 'package:flutter/material.dart';

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

class _ProductGroup {
  _ProductGroup(this.products);
  final List<Product> products;
  Product get representative => products.first;
  bool get isGrouped => products.length > 1;

  // Nombre base: quita el último token si coincide con un color conocido
  String displayNameFor(String lang) {
    final name = representative.nameFor(lang);
    final words = name.split(' ');
    if (words.length > 1 && _kColorMap.containsKey(words.last)) {
      return words.sublist(0, words.length - 1).join(' ');
    }
    // Fallback: intenta con el nombre en español
    final nameEs = representative.name;
    final wordsEs = nameEs.split(' ');
    if (wordsEs.length > 1 && _kColorMap.containsKey(wordsEs.last)) {
      return representative.nameFor(lang)
          .split(' ')
          .where((w) => !_kColorMap.containsKey(w))
          .join(' ')
          .trim()
          .isNotEmpty
          ? representative.nameFor(lang)
              .split(' ')
              .where((w) => !_kColorMap.containsKey(w))
              .join(' ')
              .trim()
          : wordsEs.sublist(0, wordsEs.length - 1).join(' ');
    }
    return name;
  }
}

class HorizontalProductList extends StatelessWidget {
  const HorizontalProductList({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onAddToCart;

  /// Recibe el producto representativo y la lista completa del grupo (null si
  /// no es un grupo de colores).
  final void Function(Product, List<Product>?) onProductTap;

  List<_ProductGroup> get _groups {
    final map = <String, List<Product>>{};
    for (final p in products) {
      final last = p.id.isNotEmpty ? p.id[p.id.length - 1] : '';
      final base = (p.id.length > 1 && RegExp(r'[A-Za-z]').hasMatch(last))
          ? p.id.substring(0, p.id.length - 1)
          : p.id;
      map.putIfAbsent(base, () => []).add(p);
    }
    return map.values.map(_ProductGroup.new).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final lang = LocaleService.instance.language.name;
        final groups = _groups;

        return SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: groups.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              final product = group.representative;
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
                          onTap: () => onProductTap(
                            product,
                            group.isGrouped ? group.products : null,
                          ),
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
                                group.isGrouped
                                    ? group.displayNameFor(lang)
                                    : product.nameFor(lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (group.isGrouped) ...[
                                const SizedBox(height: 4),
                                _ColorDots(products: group.products),
                              ],
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
      },
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    const maxDots = 5;
    final colorNames = products
        .map((p) => p.color?.split('/').first.trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
    final shown = colorNames.take(maxDots).toList();
    final extra = colorNames.length - shown.length;

    return Row(
      children: [
        ...shown.map((c) {
          if (isTransparentColor(c)) {
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9E9E9E), width: 0.8),
              ),
              child: ClipOval(
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: const ColorCheckerPainter(),
                ),
              ),
            );
          }
          final col = _kColorMap[c] ?? const Color(0xFFB0B8C4);
          final isLight = (0.299 * col.r + 0.587 * col.g + 0.114 * col.b) / 255 > 0.85;
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: col,
              shape: BoxShape.circle,
              border: Border.all(
                color: isLight ? const Color(0xFFCCCCCC) : Colors.transparent,
                width: 0.8,
              ),
            ),
          );
        }),
        if (extra > 0)
          Text(
            '+$extra',
            style: const TextStyle(fontSize: 9, color: Color(0xFF8E9AAF)),
          ),
      ],
    );
  }
}
