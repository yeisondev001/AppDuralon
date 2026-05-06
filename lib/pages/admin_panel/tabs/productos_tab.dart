import 'package:app_duralon/models/catalog_category.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';
import 'package:app_duralon/pages/admin_panel/widgets/admin_field.dart';
import 'package:app_duralon/pages/admin_panel/widgets/admin_section_label.dart';
import 'package:app_duralon/pages/admin_panel/widgets/admin_small_badge.dart';
import 'package:app_duralon/services/catalog_service.dart';
import 'package:app_duralon/services/product_seeder.dart';
import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key});

  @override
  State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showProductDialog(Product? product) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo producto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: () => _showProductDialog(null),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por código o nombre…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDDE3EE)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.streamAdmin(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error al cargar productos.',
                      style: TextStyle(color: Color(0xFFC62828)),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                  );
                }
                var products = snapshot.data!;
                if (_query.isNotEmpty) {
                  products = products
                      .where(
                        (p) =>
                            p.id.toLowerCase().contains(_query) ||
                            p.name.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: Color(0xFFB0BEC5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'Sin resultados para "$_query".'
                              : 'No hay productos aún.',
                          style:
                              const TextStyle(color: Color(0xFF8A94A6)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final product = products[i];
                    return _ProductCard(
                      product: product,
                      onEdit: () => _showProductDialog(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onEdit});
  final Product product;
  final VoidCallback onEdit;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Seguro que deseas eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProductService.delete(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(BuildContext context) async {
    try {
      await ProductService.setActive(product.id, active: !product.isActive);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: product.isActive ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A2230),
                      ),
                    ),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A94A6),
                      ),
                    ),
                    if (product.catalogId != null)
                      Text(
                        'ID: ${product.catalogId} · Tab: ${product.tab ?? '—'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'RD\$ ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Min: ${product.minOrderQty} uds',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminSmallBadge(
                          label: product.isActive ? 'Activo' : 'Inactivo',
                          color: product.isActive
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF9E9E9E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: product.isActive ? 'Desactivar' : 'Activar',
                    icon: Icon(
                      product.isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: product.isActive
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF2E7D32),
                    ),
                    onPressed: () => _toggleActive(context),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFC62828),
                    ),
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo agregar / editar producto ────────────────────────────────────────
class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});
  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _listPrice;
  late final TextEditingController _minQty;
  late final TextEditingController _stepQty;
  late final TextEditingController _palletQtyCtrl;
  late final TextEditingController _largoCtrl;
  late final TextEditingController _anchoCtrl;
  late final TextEditingController _altoCtrl;

  List<CatalogCategory> _catalogs = const [];
  CatalogCategory? _selectedCatalog;
  String? _selectedSubtype;
  List<ProductVariant> _variants = [];
  bool _saving = false;
  bool _loadingCatalogs = true;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p != null
          ? p.price.toStringAsFixed(2)
          : ProductSeeder.nuevoProductoPrecioAleatorio().toStringAsFixed(2),
    );
    _listPrice = TextEditingController(
      text: p?.listPrice != null ? p!.listPrice!.toStringAsFixed(2) : '',
    );
    _minQty = TextEditingController(text: (p?.minOrderQty ?? 1).toString());
    _stepQty = TextEditingController(text: (p?.stepQty ?? 1).toString());
    _palletQtyCtrl = TextEditingController(
        text: p?.palletQty != null ? p!.palletQty.toString() : '');
    _largoCtrl = TextEditingController(
        text: p?.largo != null ? p!.largo.toString() : '');
    _anchoCtrl = TextEditingController(
        text: p?.ancho != null ? p!.ancho.toString() : '');
    _altoCtrl = TextEditingController(
        text: p?.alto != null ? p!.alto.toString() : '');
    _variants = List.from(p?.variants ?? []);
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final all = await Future.wait([
        CatalogService.fetchByTab('hogar'),
        CatalogService.fetchByTab('industrial'),
      ]);
      final cats = [...all[0], ...all[1]];
      if (!mounted) return;
      setState(() {
        _catalogs = cats;
        _loadingCatalogs = false;
        if (_isEditing && widget.product!.catalogId != null) {
          _selectedCatalog = cats.firstWhere(
            (c) => c.id == widget.product!.catalogId,
            orElse: () => cats.first,
          );
          _selectedSubtype = widget.product!.category;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCatalogs = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _listPrice.dispose();
    _minQty.dispose();
    _stepQty.dispose();
    _palletQtyCtrl.dispose();
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _altoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'category': _selectedSubtype ?? '',
      'precio': double.tryParse(_price.text.trim()) ?? 0,
      'minOrderQty': int.tryParse(_minQty.text.trim()) ?? 1,
      'stepQty': int.tryParse(_stepQty.text.trim()) ?? 1,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_selectedCatalog != null) ...{
        'catalogId': _selectedCatalog!.id,
        'tab': _selectedCatalog!.tab,
      },
      if (_listPrice.text.trim().isNotEmpty)
        'listPrice': double.tryParse(_listPrice.text.trim()),
      if (_palletQtyCtrl.text.trim().isNotEmpty)
        'palletQty': int.tryParse(_palletQtyCtrl.text.trim()),
      if (_largoCtrl.text.trim().isNotEmpty ||
          _anchoCtrl.text.trim().isNotEmpty ||
          _altoCtrl.text.trim().isNotEmpty)
        'dimensions': <String, dynamic>{
          if (_largoCtrl.text.trim().isNotEmpty)
            'largo': double.tryParse(_largoCtrl.text.trim()),
          if (_anchoCtrl.text.trim().isNotEmpty)
            'ancho': double.tryParse(_anchoCtrl.text.trim()),
          if (_altoCtrl.text.trim().isNotEmpty)
            'alto': double.tryParse(_altoCtrl.text.trim()),
        },
      if (_variants.isNotEmpty)
        'variants': _variants.map((v) => v.toMap()).toList(),
    };

    try {
      if (_isEditing) {
        await ProductService.update(widget.product!.id, {
          ...payload,
          'price': FieldValue.delete(),
        });
      } else {
        await ProductService.add(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  Future<void> _openVariantDialog({
    ProductVariant? existing,
    int? index,
  }) async {
    final result = await showDialog<ProductVariant>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VariantDialog(existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _variants[index] = result;
      } else {
        _variants.add(result);
      }
    });
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: 420,
        height: MediaQuery.of(context).size.height * 0.78,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Datos básicos ──────────────────────────────
                AdminField(
                  controller: _name,
                  label: 'Nombre del producto',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                AdminField(
                  controller: _description,
                  label: 'Descripción (opcional)',
                  maxLines: 2,
                ),
                // ── Catálogo y subtipo ─────────────────────────
                if (_loadingCatalogs)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<CatalogCategory>(
                      initialValue: _selectedCatalog,
                      decoration: const InputDecoration(
                        labelText: 'Categoría del catálogo',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      items: _catalogs
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                '${c.title} (${c.tab == 'hogar' ? 'Hogar' : 'Industrial'})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (c) => setState(() {
                        _selectedCatalog = c;
                        _selectedSubtype = null;
                      }),
                      validator: (v) =>
                          v == null ? 'Selecciona una categoría' : null,
                    ),
                  ),
                  if (_selectedCatalog != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubtype,
                        decoration: const InputDecoration(
                          labelText: 'Subtipo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        items: _selectedCatalog!.subtypes
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (s) => setState(() => _selectedSubtype = s),
                        validator: (v) =>
                            v == null ? 'Selecciona un subtipo' : null,
                      ),
                    ),
                ],
                // ── Precios ────────────────────────────────────
                const AdminSectionLabel('Precios (RD\$)'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _price,
                        label: 'Precio base',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (double.tryParse(v.trim()) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _listPrice,
                        label: 'Precio tachado',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                // ── Cantidades ─────────────────────────────────
                const AdminSectionLabel('Cantidades'),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _minQty,
                        label: 'Mín. por pedido',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _stepQty,
                        label: 'Múltiplo',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                // ── Dimensiones del empaque ────────────────────
                const AdminSectionLabel('Empaque'),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _largoCtrl,
                        label: 'Largo (cm)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _anchoCtrl,
                        label: 'Ancho (cm)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _altoCtrl,
                        label: 'Alto (cm)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _palletQtyCtrl,
                        label: 'Cajas/pallet',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                // ── Variantes ──────────────────────────────────
                const Divider(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Variantes (color / tamaño)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A2230),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openVariantDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                if (_variants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin variantes. El precio base aplica a todos los clientes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  ...List.generate(_variants.length, (i) {
                    final v = _variants[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE3EE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v.color}${v.size != null ? ' · ${v.size}' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Código: ${v.codigo}  EAN: ${v.ean}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8A94A6),
                                  ),
                                ),
                                Text(
                                  'Minorista: RD\$${v.priceRetail.toStringAsFixed(0)}/caja  '
                                  'Dist.: RD\$${v.priceDistributor.toStringAsFixed(0)}/caja',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '${v.packQty} uds/caja · ${v.palletQty} cajas/pallet · Stock: ${v.stock}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8A94A6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.primaryBlue,
                                ),
                                onPressed: () =>
                                    _openVariantDialog(existing: v, index: i),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFC62828),
                                ),
                                onPressed: () => _removeVariant(i),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}

// ─── Diálogo de variante ───────────────────────────────────────────────────────
class _VariantDialog extends StatefulWidget {
  const _VariantDialog({this.existing});
  final ProductVariant? existing;

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigo;
  late final TextEditingController _ean;
  late final TextEditingController _color;
  late final TextEditingController _size;
  late final TextEditingController _largo;
  late final TextEditingController _ancho;
  late final TextEditingController _alto;
  late final TextEditingController _peso;
  late final TextEditingController _packQty;
  late final TextEditingController _palletQty;
  late final TextEditingController _priceRetail;
  late final TextEditingController _priceDist;
  late final TextEditingController _stock;
  bool _isActive = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codigo = TextEditingController(text: e?.codigo ?? '');
    _ean = TextEditingController(text: e?.ean ?? '');
    _color = TextEditingController(text: e?.color ?? '');
    _size = TextEditingController(text: e?.size ?? '');
    _largo = TextEditingController(text: e?.largo?.toString() ?? '');
    _ancho = TextEditingController(text: e?.ancho?.toString() ?? '');
    _alto = TextEditingController(text: e?.alto?.toString() ?? '');
    _peso = TextEditingController(text: e?.peso?.toString() ?? '');
    _packQty = TextEditingController(text: (e?.packQty ?? 1).toString());
    _palletQty = TextEditingController(text: (e?.palletQty ?? 1).toString());
    _priceRetail = TextEditingController(
      text: e != null ? e.priceRetail.toStringAsFixed(2) : '',
    );
    _priceDist = TextEditingController(
      text: e != null ? e.priceDistributor.toStringAsFixed(2) : '',
    );
    _stock = TextEditingController(text: (e?.stock ?? 0).toString());
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _codigo,
      _ean,
      _color,
      _size,
      _largo,
      _ancho,
      _alto,
      _peso,
      _packQty,
      _palletQty,
      _priceRetail,
      _priceDist,
      _stock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final dims = <String, double>{};
    if (_largo.text.trim().isNotEmpty) {
      dims['largo'] = double.parse(_largo.text.trim());
    }
    if (_ancho.text.trim().isNotEmpty) {
      dims['ancho'] = double.parse(_ancho.text.trim());
    }
    if (_alto.text.trim().isNotEmpty) {
      dims['alto'] = double.parse(_alto.text.trim());
    }
    if (_peso.text.trim().isNotEmpty) {
      dims['peso'] = double.parse(_peso.text.trim());
    }

    final variant = ProductVariant(
      codigo: _codigo.text.trim(),
      ean: _ean.text.trim(),
      color: _color.text.trim(),
      size: _size.text.trim().isNotEmpty ? _size.text.trim() : null,
      dimensions: dims,
      packQty: int.tryParse(_packQty.text.trim()) ?? 1,
      palletQty: int.tryParse(_palletQty.text.trim()) ?? 1,
      priceRetail: double.tryParse(_priceRetail.text.trim()) ?? 0,
      priceDistributor: double.tryParse(_priceDist.text.trim()) ?? 0,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      isActive: _isActive,
    );
    Navigator.pop(context, variant);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar variante' : 'Nueva variante'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identificación
                const AdminSectionLabel('Identificación'),
                AdminField(
                  controller: _codigo,
                  label: 'Código (código interno)',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                AdminField(
                  controller: _ean,
                  label: 'EAN (código de barras)',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                // Color y tamaño
                const AdminSectionLabel('Color y tamaño'),
                AdminField(
                  controller: _color,
                  label: 'Color (ej: Rojo, Surtido)',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                AdminField(
                  controller: _size,
                  label: 'Tamaño (ej: 500ml, 1L) — opcional',
                ),
                // Dimensiones
                const AdminSectionLabel('Dimensiones (cm/kg) — opcionales'),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _largo,
                        label: 'Largo',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _ancho,
                        label: 'Ancho',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _alto,
                        label: 'Alto',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _peso,
                        label: 'Peso (kg)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                // Empaque y pallet
                const AdminSectionLabel('Empaque y logística'),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _packQty,
                        label: 'Uds / caja',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || int.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _palletQty,
                        label: 'Cajas / pallet',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || int.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),
                AdminField(
                  controller: _stock,
                  label: 'Stock (cajas disponibles)',
                  keyboardType: TextInputType.number,
                ),
                // Precios
                const AdminSectionLabel('Precios (RD\$ por caja)'),
                Row(
                  children: [
                    Expanded(
                      child: AdminField(
                        controller: _priceRetail,
                        label: 'Minorista',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || double.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AdminField(
                        controller: _priceDist,
                        label: 'Distribuidor',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || double.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                  ],
                ),
                // Activo
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text(
                    'Variante activa',
                    style: TextStyle(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          onPressed: _confirm,
          child: Text(_isEditing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}
