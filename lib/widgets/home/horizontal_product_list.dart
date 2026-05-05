// Carrusel horizontal: productos agrupados por código base.
// Color: último char letra → dots de color. Tamaño: sufijo numérico → tags de tamaño.
// El tap abre ProductoScreen con la lista completa del grupo.
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

enum _GroupType { color, size, single }

class _ProductGroup {
  _ProductGroup(this.products, this.type);
  final List<Product> products;
  final _GroupType type;
  Product get representative => products.first;
  bool get isGrouped => products.length > 1;

  String displayNameFor(String lang) {
    if (type == _GroupType.color) {
      final name = representative.nameFor(lang);
      final words = name.split(' ');
      if (words.length > 1 && _kColorMap.containsKey(words.last)) {
        return words.sublist(0, words.length - 1).join(' ');
      }
      final nameEs = representative.name;
      final wordsEs = nameEs.split(' ');
      if (wordsEs.length > 1 && _kColorMap.containsKey(wordsEs.last)) {
        final cleaned = representative.nameFor(lang)
            .split(' ')
            .where((w) => !_kColorMap.containsKey(w))
            .join(' ')
            .trim();
        return cleaned.isNotEmpty
            ? cleaned
            : wordsEs.sublist(0, wordsEs.length - 1).join(' ');
      }
      return name;
    }
    if (type == _GroupType.size) {
      var name = representative.nameFor(lang);
      final words = name.split(' ');
      if (words.length > 1 && _kColorMap.containsKey(words.last)) {
        name = words.sublist(0, words.length - 1).join(' ').trim();
      }
      final cleaned = name
          .replaceAll(RegExp(r'\s+\d+\s*(lts?|[Ll]|ml)?\s*$', caseSensitive: false), '')
          .trim();
      return cleaned.isNotEmpty ? cleaned : representative.nameFor(lang);
    }
    return representative.nameFor(lang);
  }

  String sizeOf(Product p) {
    final match = RegExp(r'\d+').firstMatch(p.id);
    return match?.group(0) ?? p.id;
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
    final pass1 = <String, ({List<Product> products, _GroupType type})>{};
    for (final p in products) {
      final last = p.id.isNotEmpty ? p.id[p.id.length - 1] : '';
      String base;
      _GroupType type;
      if (p.id.length > 1 && RegExp(r'[A-Za-z]').hasMatch(last)) {
        base = p.id.substring(0, p.id.length - 1);
        type = _GroupType.color;
      } else {
        final stripped = p.id.replaceAll(RegExp(r'\d+$'), '');
        if (stripped.length >= 2 && RegExp(r'^[A-Za-z]+$').hasMatch(stripped)) {
          base = stripped;
          type = _GroupType.size;
        } else {
          base = p.id;
          type = _GroupType.single;
        }
      }
      if (pass1.containsKey(base)) {
        pass1[base]!.products.add(p);
      } else {
        pass1[base] = (products: [p], type: type);
      }
    }

    final mixedRe = RegExp(r'^([A-Za-z]+)\d+([A-Za-z]+)$');
    final mixed = <String, List<Product>>{};
    final absorbedKeys = <String>{};
    for (final entry in pass1.entries) {
      if (entry.value.products.length != 1) continue;
      final p = entry.value.products.first;
      final m = mixedRe.firstMatch(p.id);
      if (m == null) continue;
      final key = '${m.group(1)}§${m.group(2)}';
      mixed.putIfAbsent(key, () => []).add(p);
      absorbedKeys.add(entry.key);
    }

    final result = <_ProductGroup>[];
    for (final entry in mixed.entries) {
      final prods = entry.value;
      if (prods.length > 1) {
        prods.sort((a, b) {
          final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a.id)?.group(0) ?? '') ?? 0;
          final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b.id)?.group(0) ?? '') ?? 0;
          return aNum.compareTo(bNum);
        });
        result.add(_ProductGroup(prods, _GroupType.size));
      } else {
        for (final p in prods) {
          absorbedKeys.remove(p.id.substring(0, p.id.length - 1));
        }
      }
    }
    for (final entry in pass1.entries) {
      if (absorbedKeys.contains(entry.key)) continue;
      var type = entry.value.type;
      final prods = entry.value.products;
      if (prods.length == 1) type = _GroupType.single;
      if (type == _GroupType.size) {
        prods.sort((a, b) {
          final aNum = int.tryParse(RegExp(r'\d+$').firstMatch(a.id)?.group(0) ?? '') ?? 0;
          final bNum = int.tryParse(RegExp(r'\d+$').firstMatch(b.id)?.group(0) ?? '') ?? 0;
          return aNum.compareTo(bNum);
        });
      }
      result.add(_ProductGroup(prods, type));
    }
    return result;
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
          height: 278,
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
                                  alignment: Alignment.center,
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
                              if (group.isGrouped && group.type == _GroupType.color) ...[
                                const SizedBox(height: 4),
                                _ColorDots(products: group.products),
                              ] else if (group.isGrouped && group.type == _GroupType.size) ...[
                                const SizedBox(height: 4),
                                _SizeTags(group: group),
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

class _SizeTags extends StatelessWidget {
  const _SizeTags({required this.group});
  final _ProductGroup group;

  @override
  Widget build(BuildContext context) {
    const maxTags = 4;
    final shown = group.products.take(maxTags).toList();
    final extra = group.products.length - shown.length;
    return Row(
      children: [
        ...shown.map((p) {
          final label = group.sizeOf(p);
          return Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8FF),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF90A4D8), width: 0.6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C4EA5),
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
