// Grid con productos agrupados por código base.
// • Color: último carácter es letra → BARB/BARC/BARM → grupo color.
// • Tamaño: sufijo numérico con base de letras puras ≥2 → CADA5/CADA18 → grupo tamaño.
// Tap en grupo de un producto → detalle directo.
// Tap en grupo de color → selector de color en bottom sheet.
// Tap en grupo de tamaño → selector de tamaño en bottom sheet.
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/pages/producto_screen.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/color_utils.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/duralon_guest_cart_dialog.dart';
import 'package:app_duralon/widgets/product_image.dart';
import 'package:flutter/material.dart';

enum _GroupType { color, size, single }

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
  _ProductGroup(this.products, this.type);
  final List<Product> products;
  final _GroupType type;
  Product get representative => products.first;
  bool get isGrouped => products.length > 1;

  String get displayName {
    final name = representative.name;
    if (type == _GroupType.color) {
      final words = name.split(' ');
      if (words.length > 1 && _kColorMap.containsKey(words.last)) {
        return words.sublist(0, words.length - 1).join(' ');
      }
      return name;
    }
    if (type == _GroupType.size) {
      // Primero quitar palabra de color final si existe
      var n = name;
      final words = n.split(' ');
      if (words.length > 1 && _kColorMap.containsKey(words.last)) {
        n = words.sublist(0, words.length - 1).join(' ').trim();
      }
      // Luego quitar "N lts / N L / N ml" al final
      final cleaned = n
          .replaceAll(RegExp(r'\s+\d+\s*(lts?|[Ll]|ml)?\s*$', caseSensitive: false), '')
          .trim();
      return cleaned.isNotEmpty ? cleaned : name;
    }
    return name;
  }

  // Extrae el número del ID (funciona para CADA18 y CAD34R)
  String sizeOf(Product p) {
    final match = RegExp(r'\d+').firstMatch(p.id);
    return match?.group(0) ?? p.id;
  }
}

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({
    super.key,
    required this.sectionTitle,
    required this.products,
    this.isGuestMode = true,
    this.userRole,
  });

  final String sectionTitle;
  final List<Product> products;
  final bool isGuestMode;
  final String? userRole;

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _query = '';

  List<Product> get _filteredProducts {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.products;
    return widget.products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  /// Agrupa productos por código base, en dos pasadas:
  /// 1ª: color (último char letra → base sin esa letra) o tamaño simple (dígitos finales).
  /// 2ª: singles del paso 1 que cumplen letras+dígitos+letras (CAD34R / CAD51R)
  ///     con mismo prefijo+sufijo pero distinto número → grupo de tamaño.
  List<_ProductGroup> get _groups {
    final pass1 = <String, ({List<Product> products, _GroupType type})>{};
    for (final p in _filteredProducts) {
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

    // Paso 2: singles del paso 1 con patrón letras+dígitos+letras.
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
      final products = entry.value;
      if (products.length > 1) {
        products.sort((a, b) {
          final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a.id)?.group(0) ?? '') ?? 0;
          final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b.id)?.group(0) ?? '') ?? 0;
          return aNum.compareTo(bNum);
        });
        result.add(_ProductGroup(products, _GroupType.size));
      } else {
        // Solo 1 producto → no se forma grupo, devolver al paso 1
        for (final p in products) {
          absorbedKeys.remove(p.id.substring(0, p.id.length - 1));
        }
      }
    }

    for (final entry in pass1.entries) {
      if (absorbedKeys.contains(entry.key)) continue;
      var type = entry.value.type;
      final products = entry.value.products;
      if (products.length == 1) type = _GroupType.single;
      if (type == _GroupType.size) {
        products.sort((a, b) {
          final aNum = int.tryParse(RegExp(r'\d+$').firstMatch(a.id)?.group(0) ?? '') ?? 0;
          final bNum = int.tryParse(RegExp(r'\d+$').firstMatch(b.id)?.group(0) ?? '') ?? 0;
          return aNum.compareTo(bNum);
        });
      }
      result.add(_ProductGroup(products, type));
    }

    return result;
  }

  void _openProduct(BuildContext context, Product product, _ProductGroup group) {
    Navigator.push<void>(
      context,
      slideRightRoute<void>(
        ProductoScreen(
          product: product,
          colorProducts: group.isGrouped ? group.products : null,
          isGuestMode: widget.isGuestMode,
          userRole: widget.userRole,
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, _ProductGroup group) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ColorPickerSheet(
        group: group,
        onSelect: (product) {
          Navigator.pop(context);
          _openProduct(context, product, group);
        },
      ),
    );
  }

  void _showSizePicker(BuildContext context, _ProductGroup group) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SizePickerSheet(
        group: group,
        onSelect: (product) {
          Navigator.pop(context);
          _openProduct(context, product, group);
        },
      ),
    );
  }

  void _onTap(BuildContext context, _ProductGroup group) {
    if (group.isGrouped) {
      if (group.type == _GroupType.size) {
        _showSizePicker(context, group);
      } else {
        _showColorPicker(context, group);
      }
    } else {
      _openProduct(context, group.representative, group);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.sectionTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (widget.isGuestMode) showDuralonGuestCartDialog(context);
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Carrito',
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
            const SizedBox(height: 10),
            // Búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar en ${widget.sectionTitle.toLowerCase()}...',
                  hintStyle: const TextStyle(color: Color(0xFFA5ADBA)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA5ADBA)),
                  filled: true,
                  fillColor: const Color(0xFFECEEF2),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mostrando ${groups.length} producto/s:',
                  style: const TextStyle(
                    color: Color(0xFF4E596C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groups.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay productos para esta sección por ahora.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                      itemCount: groups.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.58,
                          ),
                      itemBuilder: (context, i) {
                        final group = groups[i];
                        return _ProductGroupCard(
                          group: group,
                          onTap: () => _onTap(context, group),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta del grupo ────────────────────────────────────────────────────────

class _ProductGroupCard extends StatelessWidget {
  const _ProductGroupCard({required this.group, required this.onTap});
  final _ProductGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = group.representative;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    child: ProductImage(
                      src: p.displayImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Nombre: 2 líneas para producto único, 1 línea si tiene dots de color
              Text(
                group.displayName,
                maxLines: group.isGrouped ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              if (group.isGrouped && group.type == _GroupType.color)
                _ColorDots(products: group.products)
              else if (group.isGrouped && group.type == _GroupType.size)
                _SizeTags(group: group)
              else
                Text(
                  'RD\$ ${p.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    const maxDots = 5;
    final colors = products
        .map((p) => p.color?.split('/').first.trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toList();
    final shown = colors.take(maxDots).toList();
    final extra = colors.length - shown.length;

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

// ─── Tags de tamaño en la card ────────────────────────────────────────────────

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

// ─── Bottom sheet selector de color ──────────────────────────────────────────

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.group, required this.onSelect});
  final _ProductGroup group;
  final ValueChanged<Product> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            group.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona un color',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: group.products.map((p) {
              final colorName = p.color?.split('/').first.trim() ?? '';
              final isTransparent = isTransparentColor(colorName);
              final col = _kColorMap[colorName] ?? const Color(0xFFB0B8C4);
              final isLight = (0.299 * col.r + 0.587 * col.g + 0.114 * col.b) / 255 > 0.85;
              return GestureDetector(
                onTap: () => onSelect(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isTransparent ? Colors.white : col.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTransparent ? const Color(0xFF9E9E9E) : col.withValues(alpha: 0.6),
                      width: isTransparent ? 1.5 : 1.0,
                    ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isTransparent
                              ? const Color(0xFF374151)
                              : (isLight ? const Color(0xFF374151) : col.withValues(alpha: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet selector de tamaño ─────────────────────────────────────────

class _SizePickerSheet extends StatelessWidget {
  const _SizePickerSheet({required this.group, required this.onSelect});
  final _ProductGroup group;
  final ValueChanged<Product> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            group.displayName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona un tamaño',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: group.products.map((p) {
              final sizeLabel = group.sizeOf(p);
              return GestureDetector(
                onTap: () => onSelect(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE8FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sizeLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
