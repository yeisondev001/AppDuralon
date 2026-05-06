import 'package:app_duralon/models/catalog_category.dart';
import 'package:app_duralon/pages/admin_panel/widgets/admin_field.dart';
import 'package:app_duralon/pages/admin_panel/widgets/admin_small_badge.dart';
import 'package:app_duralon/services/catalog_service.dart';
import 'package:app_duralon/services/product_seeder.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

class CatalogosTab extends StatefulWidget {
  const CatalogosTab({super.key});

  @override
  State<CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<CatalogosTab> {
  bool _seeding = false;
  bool _seedingHogarCatalog = false;
  bool _seedingIndustrialCatalog = false;
  bool _seedingDimensions = false;
  String _hogarCatalogProgress = '';
  String _industrialCatalogProgress = '';
  String _dimensionsProgress = '';

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await CatalogService.seedFromLocalData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catálogos cargados en Firebase correctamente.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar catálogos: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _seedCatalogHogar2026() async {
    setState(() {
      _seedingHogarCatalog = true;
      _hogarCatalogProgress = 'Iniciando…';
    });
    try {
      await ProductSeeder.seedCatalogHogar2026(
        onProgress: (msg) {
          if (mounted) setState(() => _hogarCatalogProgress = msg);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Catálogo Hogar 2026 cargado exitosamente en Firebase!',
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar catálogo Hogar 2026: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _seedingHogarCatalog = false;
          _hogarCatalogProgress = '';
        });
      }
    }
  }

  Future<void> _seedCatalogIndustrial2025() async {
    setState(() {
      _seedingIndustrialCatalog = true;
      _industrialCatalogProgress = 'Iniciando…';
    });
    try {
      await ProductSeeder.seedCatalogIndustrial2025(
        onProgress: (msg) {
          if (mounted) setState(() => _industrialCatalogProgress = msg);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Catálogo Industrial 2025 cargado exitosamente en Firebase!',
            ),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar catálogo Industrial 2025: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _seedingIndustrialCatalog = false;
          _industrialCatalogProgress = '';
        });
      }
    }
  }

  Future<void> _seedDimensions() async {
    setState(() {
      _seedingDimensions = true;
      _dimensionsProgress = 'Iniciando…';
    });
    try {
      final result = await ProductSeeder.seedProductDimensions(
        onProgress: (msg) {
          if (mounted) setState(() => _dimensionsProgress = msg);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Empaques actualizados: ${result['updated']} · sin datos: ${result['skipped']}',
            ),
            backgroundColor: const Color(0xFF0059B7),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar empaques: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _seedingDimensions = false;
          _dimensionsProgress = '';
        });
      }
    }
  }

  void _showCategoryDialog(BuildContext ctx, {CatalogCategory? existing}) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _CatalogDialog(existing: existing),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    CatalogCategory cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar "${cat.title}"?\n\nLos productos asociados no se borran.',
        ),
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
      await CatalogService.delete(cat.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Categoría eliminada.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nueva categoría',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: () => _showCategoryDialog(context),
      ),
      body: StreamBuilder<List<CatalogCategory>>(
        stream: CatalogService.streamAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
            );
          }
          final cats = snapshot.data;
          if (cats == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          return Column(
            children: [
              // Banner de carga inicial
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Carga las categorías por defecto desde el árbol de catálogo '
                          'local. Ejecuta una sola vez para inicializar Firebase.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: _seeding ? null : _seed,
                        child: _seeding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cargar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Banner Catálogo Hogar 2026 ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFFF57F17),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Catálogo Hogar 2026 — Carga categorías y productos de hogar '
                              '(Cocina, Hogar, Jardinería, Muebles e Infantil).',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF795548),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF57F17),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _seedingHogarCatalog
                                ? null
                                : _seedCatalogHogar2026,
                            child: _seedingHogarCatalog
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Cargar Hogar (${ProductSeeder.hogarProductsCount})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_seedingHogarCatalog &&
                          _hogarCatalogProgress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 28),
                          child: Text(
                            _hogarCatalogProgress,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Banner Catálogo Industrial 2025 ───────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warehouse_rounded,
                            color: Color(0xFF2E7D32),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Catálogo Industrial 2025 — Carga Cajones, Paletas y Otros.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _seedingIndustrialCatalog
                                ? null
                                : _seedCatalogIndustrial2025,
                            child: _seedingIndustrialCatalog
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Cargar Industrial (${ProductSeeder.industrialProductsCount})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_seedingIndustrialCatalog &&
                          _industrialCatalogProgress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 28),
                          child: Text(
                            _industrialCatalogProgress,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Banner Empaques / Dimensiones ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF0059B7),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Empaques 2026 — Actualiza packQty, palletQty, EAN y dimensiones de 666 productos.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0059B7),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onPressed: _seedingDimensions ? null : _seedDimensions,
                            child: _seedingDimensions
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Cargar Empaques',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_seedingDimensions && _dimensionsProgress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 28),
                          child: Text(
                            _dimensionsProgress,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (cats.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 56,
                          color: Color(0xFFB0BEC5),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No hay categorías en Firebase aún.',
                          style: TextStyle(color: Color(0xFF8A94A6)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Presiona "Cargar" para inicializar con los datos por defecto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: cats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final cat = cats[i];
                      return _CatalogCard(
                        category: cat,
                        onEdit: () =>
                            _showCategoryDialog(context, existing: cat),
                        onDelete: () => _deleteCategory(context, cat),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });
  final CatalogCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isHogar = category.tab == 'hogar';
    return Container(
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isHogar ? const Color(0xFFFFECEC) : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isHogar ? Icons.home_outlined : Icons.factory_outlined,
                color: isHogar ? AppColors.primaryRed : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2230),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children:
                        category.subtypes
                            .take(4)
                            .map(
                              (s) => AdminSmallBadge(
                                label: s,
                                color: isHogar
                                    ? AppColors.primaryRed
                                    : AppColors.primaryBlue,
                              ),
                            )
                            .toList()
                          ..addAll(
                            category.subtypes.length > 4
                                ? [
                                    AdminSmallBadge(
                                      label: '+${category.subtypes.length - 4}',
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ]
                                : [],
                          ),
                  ),
                  const SizedBox(height: 3),
                  AdminSmallBadge(
                    label: isHogar ? 'HOGAR' : 'INDUSTRIAL',
                    color: isHogar
                        ? AppColors.primaryRed
                        : AppColors.primaryBlue,
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
                  tooltip: 'Eliminar',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFC62828),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Diálogo agregar / editar categoría ───────────────────────────────────────
class _CatalogDialog extends StatefulWidget {
  const _CatalogDialog({this.existing});
  final CatalogCategory? existing;

  @override
  State<_CatalogDialog> createState() => _CatalogDialogState();
}

class _CatalogDialogState extends State<_CatalogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _title;
  late final TextEditingController _order;
  late final TextEditingController _subtypes;
  late String _tab;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = TextEditingController(text: e?.id ?? '');
    _title = TextEditingController(text: e?.title ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _subtypes = TextEditingController(text: e?.subtypes.join('\n') ?? '');
    _tab = e?.tab ?? 'hogar';
  }

  @override
  void dispose() {
    _id.dispose();
    _title.dispose();
    _order.dispose();
    _subtypes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final subtypesList = _subtypes.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final data = {
        'title': _title.text.trim(),
        'tab': _tab,
        'order': int.tryParse(_order.text.trim()) ?? 0,
        'subtypes': subtypesList,
      };
      if (_isEditing) {
        await CatalogService.update(widget.existing!.id, data);
      } else {
        final cat = CatalogCategory(
          id: _id.text.trim(),
          title: _title.text.trim(),
          tab: _tab,
          order: int.tryParse(_order.text.trim()) ?? 0,
          subtypes: subtypesList,
        );
        await CatalogService.add(cat);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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
    return AlertDialog(
      title: Text(_isEditing ? 'Editar categoría' : 'Nueva categoría'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEditing)
                  AdminField(
                    controller: _id,
                    label: 'ID (ej: cocina)',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (RegExp(r'\s').hasMatch(v.trim())) {
                        return 'Sin espacios (usa _)';
                      }
                      return null;
                    },
                  ),
                AdminField(
                  controller: _title,
                  label: 'Título visible',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _tab,
                    decoration: const InputDecoration(
                      labelText: 'Tab',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                      DropdownMenuItem(
                        value: 'industrial',
                        child: Text('Industrial'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _tab = v);
                    },
                  ),
                ),
                AdminField(
                  controller: _order,
                  label: 'Orden de aparición',
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _subtypes,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Subtipos (uno por línea)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                      hintText: 'Envases\nJarras\nVasos...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Agrega al menos un subtipo'
                        : null,
                  ),
                ),
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
