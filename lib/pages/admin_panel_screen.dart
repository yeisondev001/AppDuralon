import 'package:app_duralon/models/catalog_category.dart';
import 'package:app_duralon/models/order.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/models/product_variant.dart';
import 'package:app_duralon/pages/mis_pedidos_screen.dart';
import 'package:app_duralon/services/catalog_service.dart';
import 'package:app_duralon/services/order_service.dart';
import 'package:app_duralon/services/product_seeder.dart';
import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Panel de administración',
          style: TextStyle(
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: const Color(0xFF8A94A6),
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Usuarios'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Catálogos'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Órdenes'),
            Tab(icon: Icon(Icons.bug_report_outlined), text: 'Pruebas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _UsuariosTab(),
          _CatalogosTab(),
          _ProductosTab(),
          _OrdenesTab(),
          _PruebasTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PESTAÑA USUARIOS
// ═══════════════════════════════════════════════════════════════════════════════
class _UsuariosTab extends StatelessWidget {
  const _UsuariosTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error al cargar usuarios.',
                style: TextStyle(color: Color(0xFFC62828))),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay usuarios registrados.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final uid = docs[i].id;
            return _UserCard(uid: uid, data: data);
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.uid, required this.data});
  final String uid;
  final Map<String, dynamic> data;

  static const _roles = [
    'cliente_minorista',
    'cliente_distribuidor',
    'vendedor',
    'admin',
  ];
  static const _roleColors = {
    'cliente_minorista':   Color(0xFF1565C0),
    'cliente_distribuidor': Color(0xFF00838F),
    'cliente':             Color(0xFF1565C0), // retrocompat
    'vendedor':            Color(0xFFE65100),
    'admin':               Color(0xFFC62828),
  };
  static const _roleLabels = {
    'cliente_minorista':   'Cliente Minorista',
    'cliente_distribuidor': 'Cliente Distribuidor',
    'cliente':             'Cliente',             // retrocompat
    'vendedor':            'Vendedor',
    'admin':               'Administrador',
  };

  Future<void> _changeRole(BuildContext context, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'rol': newRole,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rol cambiado a "${_roleLabels[newRole] ?? newRole}" correctamente.'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar rol: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que deseas eliminar a "${data['nombre'] ?? data['correo'] ?? uid}"?\n\n'
          'Solo se eliminará el documento de Firestore. Para eliminar la cuenta de autenticación hazlo desde Firebase Console.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('customers').doc(uid));
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario eliminado de Firestore.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    }
  }

  void _showRoleDialog(BuildContext context) {
    final currentRole = data['rol'] as String? ?? 'cliente';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _roles.map((role) {
            final color = _roleColors[role] ?? Colors.grey;
            final isSelected = role == currentRole;
            return ListTile(
              leading: CircleAvatar(
                radius: 8,
                backgroundColor: color,
              ),
              title: Text(
                _roleLabels[role] ?? role,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: color)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                if (role != currentRole) _changeRole(context, role);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['nombre'] as String? ?? '';
    final email = data['correo'] as String? ?? '';
    final role = data['rol'] as String? ?? 'cliente';
    final status = data['estado'] as String? ?? '';
    final photoUrl = data['fotoUrl'] as String?;
    final roleColor = _roleColors[role] ?? Colors.grey;
    final roleLabel = _roleLabels[role] ?? role;

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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD6E4F0),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A2230))),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7685))),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _SmallBadge(label: roleLabel, color: roleColor),
                      if (status.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _SmallBadge(
                          label: status,
                          color: status == 'activo'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF9E9E9E),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Cambiar rol',
                  icon: const Icon(Icons.manage_accounts_rounded,
                      color: AppColors.primaryBlue),
                  onPressed: () => _showRoleDialog(context),
                ),
                IconButton(
                  tooltip: 'Eliminar usuario',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFC62828)),
                  onPressed: () => _deleteUser(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PESTAÑA CATÁLOGOS
// ═══════════════════════════════════════════════════════════════════════════════
class _CatalogosTab extends StatefulWidget {
  const _CatalogosTab();

  @override
  State<_CatalogosTab> createState() => _CatalogosTabState();
}

class _CatalogosTabState extends State<_CatalogosTab> {
  bool _seeding = false;
  bool _seedingHogarCatalog = false;
  bool _seedingIndustrialCatalog = false;
  String _hogarCatalogProgress = '';
  String _industrialCatalogProgress = '';

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
            content: Text('¡Catálogo Hogar 2026 cargado exitosamente en Firebase!'),
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
            content: Text('¡Catálogo Industrial 2025 cargado exitosamente en Firebase!'),
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

  void _showCategoryDialog(BuildContext ctx,
      {CatalogCategory? existing}) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _CatalogDialog(existing: existing),
    );
  }

  Future<void> _deleteCategory(
      BuildContext context, CatalogCategory cat) async {
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
                foregroundColor: const Color(0xFFC62828)),
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
        label: const Text('Nueva categoría',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showCategoryDialog(context),
      ),
      body: StreamBuilder<List<CatalogCategory>>(
        stream: CatalogService.streamAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFFC62828))),
            );
          }
          final cats = snapshot.data;
          if (cats == null) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryBlue));
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
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Carga las categorías por defecto desde el árbol de catálogo '
                          'local. Ejecuta una sola vez para inicializar Firebase.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: _seeding ? null : _seed,
                        child: _seeding
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Cargar',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
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
                          const Icon(Icons.inventory_2_rounded,
                              color: Color(0xFFF57F17), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Catálogo Hogar 2026 — Carga categorías y productos de hogar '
                              '(Cocina, Hogar, Jardinería, Muebles e Infantil).',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF795548)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF57F17),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed:
                                _seedingHogarCatalog ? null : _seedCatalogHogar2026,
                            child: _seedingHogarCatalog
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Cargar Hogar (${ProductSeeder.hogarProductsCount})',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (_seedingHogarCatalog && _hogarCatalogProgress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 28),
                          child: Text(
                            _hogarCatalogProgress,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF795548)),
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
                          const Icon(Icons.warehouse_rounded,
                              color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Catálogo Industrial 2025 — Carga Cajones, Paletas y Otros.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1B5E20)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: _seedingIndustrialCatalog
                                ? null
                                : _seedCatalogIndustrial2025,
                            child: _seedingIndustrialCatalog
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Cargar Industrial (${ProductSeeder.industrialProductsCount})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
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
                                fontSize: 11, color: Color(0xFF1B5E20)),
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
                        Icon(Icons.category_outlined,
                            size: 56, color: Color(0xFFB0BEC5)),
                        SizedBox(height: 12),
                        Text('No hay categorías en Firebase aún.',
                            style: TextStyle(color: Color(0xFF8A94A6))),
                        SizedBox(height: 6),
                        Text(
                          'Presiona "Cargar" para inicializar con los datos por defecto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8A94A6)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final cat = cats[i];
                      return _CatalogCard(
                        category: cat,
                        onEdit: () =>
                            _showCategoryDialog(context, existing: cat),
                        onDelete: () =>
                            _deleteCategory(context, cat),
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
  const _CatalogCard(
      {required this.category,
      required this.onEdit,
      required this.onDelete});
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
                color: isHogar
                    ? const Color(0xFFFFECEC)
                    : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isHogar
                    ? Icons.home_outlined
                    : Icons.factory_outlined,
                color: isHogar
                    ? AppColors.primaryRed
                    : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A2230))),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: category.subtypes
                        .take(4)
                        .map((s) => _SmallBadge(
                              label: s,
                              color: isHogar
                                  ? AppColors.primaryRed
                                  : AppColors.primaryBlue,
                            ))
                        .toList()
                      ..addAll(
                        category.subtypes.length > 4
                            ? [
                                _SmallBadge(
                                    label:
                                        '+${category.subtypes.length - 4}',
                                    color: const Color(0xFF9E9E9E))
                              ]
                            : [],
                      ),
                  ),
                  const SizedBox(height: 3),
                  _SmallBadge(
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
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primaryBlue),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFC62828)),
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
    _subtypes = TextEditingController(
        text: e?.subtypes.join('\n') ?? '');
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
      title: Text(
          _isEditing ? 'Editar categoría' : 'Nueva categoría'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_isEditing)
                  _Field(
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
                _Field(
                  controller: _title,
                  label: 'Título visible',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    value: _tab,
                    decoration: const InputDecoration(
                      labelText: 'Tab',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'hogar', child: Text('Hogar')),
                      DropdownMenuItem(
                          value: 'industrial',
                          child: Text('Industrial')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _tab = v);
                    },
                  ),
                ),
                _Field(
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
                          horizontal: 12, vertical: 10),
                      isDense: true,
                      hintText: 'Envases\nJarras\nVasos...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
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
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEditing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PESTAÑA PRODUCTOS
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductosTab extends StatelessWidget {
  const _ProductosTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo producto',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showProductDialog(context, null),
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService.streamAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar productos.',
                  style: TextStyle(color: Color(0xFFC62828))),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryBlue));
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 56, color: Color(0xFFB0BEC5)),
                  SizedBox(height: 12),
                  Text('No hay productos aún.',
                      style: TextStyle(color: Color(0xFF8A94A6))),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final product = products[i];
              return _ProductCard(
                product: product,
                onEdit: () => _showProductDialog(context, product),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product? product) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductDialog(product: product),
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
        content:
            Text('¿Seguro que deseas eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828)),
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
      await ProductService.setActive(product.id,
          active: !product.isActive);
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
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A2230))),
                    Text(product.category,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A94A6))),
                    if (product.catalogId != null)
                      Text('ID: ${product.catalogId} · Tab: ${product.tab ?? '—'}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFB0BEC5))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'RD\$ ${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text('Min: ${product.minOrderQty} uds',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8A94A6))),
                        const SizedBox(width: 8),
                        _SmallBadge(
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
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.primaryBlue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: product.isActive
                        ? 'Desactivar'
                        : 'Activar',
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
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFC62828)),
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
            : ProductSeeder.nuevoProductoPrecioAleatorio().toStringAsFixed(2));
    _listPrice = TextEditingController(
        text: p?.listPrice != null ? p!.listPrice!.toStringAsFixed(2) : '');
    _minQty  = TextEditingController(text: (p?.minOrderQty ?? 1).toString());
    _stepQty = TextEditingController(text: (p?.stepQty ?? 1).toString());
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: const Color(0xFFC62828),
        ));
      }
    }
  }

  Future<void> _openVariantDialog({ProductVariant? existing, int? index}) async {
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
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Datos básicos ──────────────────────────────
                _Field(
                  controller: _name,
                  label: 'Nombre del producto',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                _Field(
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
                      value: _selectedCatalog,
                      decoration: const InputDecoration(
                        labelText: 'Categoría del catálogo',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: _catalogs
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                    '${c.title} (${c.tab == 'hogar' ? 'Hogar' : 'Industrial'})'),
                              ))
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
                        value: _selectedSubtype,
                        decoration: const InputDecoration(
                          labelText: 'Subtipo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        items: _selectedCatalog!.subtypes
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (s) =>
                            setState(() => _selectedSubtype = s),
                        validator: (v) =>
                            v == null ? 'Selecciona un subtipo' : null,
                      ),
                    ),
                ],
                // ── Precio general (fallback sin variantes) ────
                _Field(
                  controller: _price,
                  label: 'Precio base (RD\$)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (double.tryParse(v.trim()) == null) return 'Número inválido';
                    return null;
                  },
                ),
                _Field(
                  controller: _listPrice,
                  label: 'Precio anterior / tachado (opcional)',
                  keyboardType: TextInputType.number,
                ),
                _Field(
                  controller: _minQty,
                  label: 'Cantidad mínima',
                  keyboardType: TextInputType.number,
                ),
                _Field(
                  controller: _stepQty,
                  label: 'Múltiplo de compra',
                  keyboardType: TextInputType.number,
                ),

                // ── Variantes ──────────────────────────────────
                const Divider(height: 24),
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
                          foregroundColor: AppColors.primaryBlue),
                    ),
                  ],
                ),
                if (_variants.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Sin variantes. El precio base aplica a todos los clientes.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
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
                                      color: Color(0xFF8A94A6)),
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
                                      color: Color(0xFF8A94A6)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                constraints:
                                    const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.primaryBlue),
                                onPressed: () =>
                                    _openVariantDialog(existing: v, index: i),
                              ),
                              IconButton(
                                constraints:
                                    const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: Color(0xFFC62828)),
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
                      strokeWidth: 2, color: Colors.white))
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
    _codigo        = TextEditingController(text: e?.codigo ?? '');
    _ean        = TextEditingController(text: e?.ean ?? '');
    _color      = TextEditingController(text: e?.color ?? '');
    _size       = TextEditingController(text: e?.size ?? '');
    _largo      = TextEditingController(text: e?.largo?.toString() ?? '');
    _ancho      = TextEditingController(text: e?.ancho?.toString() ?? '');
    _alto       = TextEditingController(text: e?.alto?.toString() ?? '');
    _peso       = TextEditingController(text: e?.peso?.toString() ?? '');
    _packQty    = TextEditingController(text: (e?.packQty  ?? 1).toString());
    _palletQty  = TextEditingController(text: (e?.palletQty ?? 1).toString());
    _priceRetail = TextEditingController(
        text: e != null ? e.priceRetail.toStringAsFixed(2) : '');
    _priceDist  = TextEditingController(
        text: e != null ? e.priceDistributor.toStringAsFixed(2) : '');
    _stock      = TextEditingController(text: (e?.stock ?? 0).toString());
    _isActive   = e?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [_codigo,_ean,_color,_size,_largo,_ancho,_alto,_peso,
                     _packQty,_palletQty,_priceRetail,_priceDist,_stock]) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    final dims = <String, double>{};
    if (_largo.text.trim().isNotEmpty) dims['largo'] = double.parse(_largo.text.trim());
    if (_ancho.text.trim().isNotEmpty) dims['ancho'] = double.parse(_ancho.text.trim());
    if (_alto.text.trim().isNotEmpty)  dims['alto']  = double.parse(_alto.text.trim());
    if (_peso.text.trim().isNotEmpty)  dims['peso']  = double.parse(_peso.text.trim());

    final variant = ProductVariant(
      codigo:              _codigo.text.trim(),
      ean:              _ean.text.trim(),
      color:            _color.text.trim(),
      size:             _size.text.trim().isNotEmpty ? _size.text.trim() : null,
      dimensions:       dims,
      packQty:          int.tryParse(_packQty.text.trim())   ?? 1,
      palletQty:        int.tryParse(_palletQty.text.trim()) ?? 1,
      priceRetail:      double.tryParse(_priceRetail.text.trim()) ?? 0,
      priceDistributor: double.tryParse(_priceDist.text.trim())   ?? 0,
      stock:            int.tryParse(_stock.text.trim()) ?? 0,
      isActive:         _isActive,
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
                const _SectionLabel('Identificación'),
                _Field(
                  controller: _codigo,
                  label: 'Código (código interno)',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                _Field(
                  controller: _ean,
                  label: 'EAN (código de barras)',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                // Color y tamaño
                const _SectionLabel('Color y tamaño'),
                _Field(
                  controller: _color,
                  label: 'Color (ej: Rojo, Surtido)',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                _Field(
                  controller: _size,
                  label: 'Tamaño (ej: 500ml, 1L) — opcional',
                ),
                // Dimensiones
                const _SectionLabel('Dimensiones (cm/kg) — opcionales'),
                Row(children: [
                  Expanded(child: _Field(controller: _largo, label: 'Largo',
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(controller: _ancho, label: 'Ancho',
                      keyboardType: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: _Field(controller: _alto, label: 'Alto',
                      keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(controller: _peso, label: 'Peso (kg)',
                      keyboardType: TextInputType.number)),
                ]),
                // Empaque y pallet
                const _SectionLabel('Empaque y logística'),
                Row(children: [
                  Expanded(child: _Field(
                    controller: _packQty,
                    label: 'Uds / caja',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(
                    controller: _palletQty,
                    label: 'Cajas / pallet',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                  )),
                ]),
                _Field(
                  controller: _stock,
                  label: 'Stock (cajas disponibles)',
                  keyboardType: TextInputType.number,
                ),
                // Precios
                const _SectionLabel('Precios (RD\$ por caja)'),
                Row(children: [
                  Expanded(child: _Field(
                    controller: _priceRetail,
                    label: 'Minorista',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || double.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _Field(
                    controller: _priceDist,
                    label: 'Distribuidor',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || double.tryParse(v.trim()) == null)
                            ? 'Requerido'
                            : null,
                  )),
                ]),
                // Activo
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Variante activa', style: TextStyle(fontSize: 14)),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A94A6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PESTAÑA PRUEBAS
// ═══════════════════════════════════════════════════════════════════════════════
class _PruebasTab extends StatefulWidget {
  const _PruebasTab();

  @override
  State<_PruebasTab> createState() => _PruebasTabState();
}

class _PruebasTabState extends State<_PruebasTab> {
  bool _crashlyticsSending = false;
  bool _migrandoPrecios = false;
  String? _resultado;


  Future<void> _enviarErrorPrueba() async {
    setState(() {
      _crashlyticsSending = true;
      _resultado = null;
    });
    try {
      await FirebaseCrashlytics.instance.recordError(
        Exception('Error de prueba desde el panel de admin'),
        StackTrace.current,
        reason: 'Test manual desde _PruebasTab',
        fatal: false,
      );
      await FirebaseCrashlytics.instance.sendUnsentReports();
      if (mounted) {
        setState(() => _resultado =
            '✓ Reporte enviado. Revisa Firebase Console → Crashlytics.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resultado = '✗ Error al enviar: $e');
      }
    } finally {
      if (mounted) setState(() => _crashlyticsSending = false);
    }
  }


  void _forzarCrashFatal() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crash fatal'),
        content: const Text(
          'Esto cerrará la app inmediatamente.\n'
          'Vuelve a abrirla para que se envíe el reporte a Firebase.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828)),
            onPressed: () {
              Navigator.pop(ctx, true);
              Future<void>.delayed(const Duration(milliseconds: 300), () {
                FirebaseCrashlytics.instance.crash();
              });
            },
            child: const Text('Sí, crashear'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrarPriceAPrecioAleatorio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrar colección products'),
        content: const Text(
          'Esto actualizará todos los productos en Firebase:\n\n'
          '- Elimina el campo "price"\n'
          '- Escribe un nuevo campo "precio" con valor aleatorio\n\n'
          'Esta acción es para pruebas. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, migrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _migrandoPrecios = true;
      _resultado = null;
    });

    try {
      final total = await ProductService.migratePriceToPrecioWithRandomValues();
      if (!mounted) return;
      setState(() {
        _resultado = '✓ Migración completada. Productos actualizados: $total';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultado = '✗ Error en migración de precios: $e';
      });
    } finally {
      if (mounted) setState(() => _migrandoPrecios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Card: Crashlytics ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bug_report_outlined,
                          color: Color(0xFFE65100)),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firebase Crashlytics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2230),
                          ),
                        ),
                        Text(
                          'Prueba el reporte de errores',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF8A94A6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error no fatal',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2230)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Envía un error de prueba a Firebase sin cerrar la app. '
                      'Aparece en Crashlytics como "Non-fatal".',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                          side:
                              const BorderSide(color: Color(0xFFE65100)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _crashlyticsSending
                            ? null
                            : _enviarErrorPrueba,
                        icon: _crashlyticsSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE65100)),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Enviar error de prueba'),
                      ),
                    ),
                    if (_resultado != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _resultado!.startsWith('✓')
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _resultado!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _resultado!.startsWith('✓')
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crash fatal',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2230)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cierra la app inmediatamente. Vuelve a abrirla para '
                      'que se envíe el reporte. Aparece en Crashlytics como "Fatal".',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _forzarCrashFatal,
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text(
                          'Forzar crash fatal',
                          style:
                              TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firestore products (migración de prueba)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2230)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Renombra campo price a precio y asigna precios aleatorios '
                      'en todos los documentos de products.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _migrandoPrecios
                            ? null
                            : _migrarPriceAPrecioAleatorio,
                        icon: _migrandoPrecios
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.swap_horiz_rounded),
                        label: Text(
                          _migrandoPrecios
                              ? 'Migrando precios...'
                              : 'Migrar price -> precio + aleatorio',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Los reportes aparecen en Firebase Console → Crashlytics '
                  'en 1-2 minutos. En modo debug los errores no fatales '
                  'se envían, pero los crashes fatales requieren modo release.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Badge pequeño ─────────────────────────────────────────────────────────────
class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab Órdenes (admin)
// ═══════════════════════════════════════════════════════════════════════════════
class _OrdenesTab extends StatelessWidget {
  const _OrdenesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: OrderService.streamAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('Sin órdenes aún', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _AdminOrderCard(order: orders[i]),
        );
      },
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order});
  final Order order;

  static const _statusOptions = [
    OrderStatus.pendiente,
    OrderStatus.confirmado,
    OrderStatus.enProceso,
    OrderStatus.enviado,
    OrderStatus.entregado,
    OrderStatus.cancelado,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName.isNotEmpty ? order.customerName : order.customerEmail,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusChipAdmin(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.totalUnidades} uds · ${_fmtDate(order.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              Text(
                'RD\$${_fmtNum(order.total)}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<OrderStatus>(
                  value: order.status,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  items: _statusOptions.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.label, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (s) {
                    if (s != null) OrderService.updateStatus(order.id, s);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                color: AppColors.primaryBlue,
                tooltip: 'Ver detalle',
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => OrdenDetalleScreen(order: order)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChipAdmin extends StatelessWidget {
  const _StatusChipAdmin({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  (Color, Color) _colors(OrderStatus s) {
    switch (s) {
      case OrderStatus.pendiente:  return (const Color(0xFFB45309), const Color(0xFFFEF3C7));
      case OrderStatus.confirmado: return (const Color(0xFF1D4ED8), const Color(0xFFDBEAFE));
      case OrderStatus.enProceso:  return (const Color(0xFF7C3AED), const Color(0xFFEDE9FE));
      case OrderStatus.enviado:    return (const Color(0xFF0F766E), const Color(0xFFCCFBF1));
      case OrderStatus.entregado:  return (const Color(0xFF15803D), const Color(0xFFDCFCE7));
      case OrderStatus.cancelado:  return (const Color(0xFFB91C1C), const Color(0xFFFFE5E8));
    }
  }
}

String _fmtNum(double n) => n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
