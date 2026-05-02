// Agrupa productos cuyo código sólo difiere en el último carácter (color).
// Ejemplo: MC16VB (Blanco) y MC16VC (Crema) → un solo producto "MC16V" con
// dos variantes seleccionables en la pantalla de producto.
//
// Reglas para agrupar (todas obligatorias):
//   - mismo código base (id sin el último carácter)
//   - todos los miembros del grupo tienen `color` no vacío
//   - todos los miembros tienen el mismo `name`
// Si una sola condición falla, los productos se devuelven tal cual.
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';

/// Devuelve la lista agrupada por código base. Conserva el orden de aparición
/// del primer miembro de cada grupo.
List<Product> groupProductsByBaseCode(List<Product> products) {
  if (products.isEmpty) return products;

  final groups = <String, List<Product>>{};
  final order = <String>[];

  for (final p in products) {
    final base = _baseCode(p.id);
    if (!groups.containsKey(base)) {
      order.add(base);
      groups[base] = [];
    }
    groups[base]!.add(p);
  }

  final out = <Product>[];
  for (final base in order) {
    final group = groups[base]!;

    // Sin grupo o no califica → se devuelve(n) tal cual.
    if (group.length < 2 || !_canMerge(group)) {
      out.addAll(group);
      continue;
    }

    out.add(_mergeAsVariants(group));
  }
  return out;
}

String _baseCode(String id) {
  if (id.length <= 1) return id;
  return id.substring(0, id.length - 1);
}

/// Solo agrupar si todos tienen color no vacío y el mismo nombre.
bool _canMerge(List<Product> group) {
  final firstName = group.first.name.trim().toLowerCase();
  for (final p in group) {
    final c = p.color?.trim() ?? '';
    if (c.isEmpty) return false;
    if (p.name.trim().toLowerCase() != firstName) return false;
  }
  return true;
}

/// Toma el primer producto como plantilla y mete todos como variantes.
Product _mergeAsVariants(List<Product> group) {
  final template = group.first;

  final variants = group.map((p) {
    return ProductVariant(
      codigo: p.id,
      ean: p.ean ?? '',
      color: p.color ?? 'Sin color',
      dimensions: p.dimensions,
      packQty: p.packQty ?? (p.minOrderQty > 0 ? p.minOrderQty : 1),
      palletQty: p.palletQty ?? 0,
      priceRetail: p.price,
      priceDistributor: p.price,
      stock: 0,
      isActive: p.isActive,
      imageUrl: p.imageUrl,
      cbm: p.cbm,
    );
  }).toList();

  return template.copyWith(variants: variants);
}
