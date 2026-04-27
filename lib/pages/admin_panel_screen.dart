import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/styles/app_style.dart';

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
    _tabs = TabController(length: 2, vsync: this);
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
            Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: 'Productos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _UsuariosTab(),
          _ProductosTab(),
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

  static const _roles = ['cliente', 'vendedor', 'admin'];
  static const _roleColors = {
    'cliente': Color(0xFF1565C0),
    'vendedor': Color(0xFFE65100),
    'admin': Color(0xFFC62828),
  };
  static const _roleLabels = {
    'cliente': 'Cliente',
    'vendedor': 'Vendedor',
    'admin': 'Administrador',
  };

  Future<void> _changeRole(BuildContext context, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
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
          '¿Seguro que deseas eliminar a "${data['displayName'] ?? data['email'] ?? uid}"?\n\n'
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
      batch.delete(
          FirebaseFirestore.instance.collection('users').doc(uid));
      batch.delete(
          FirebaseFirestore.instance.collection('customers').doc(uid));
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
    final currentRole = data['role'] as String? ?? 'cliente';
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
    final name = data['displayName'] as String? ?? '';
    final email = data['email'] as String? ?? '';
    final role = data['role'] as String? ?? 'cliente';
    final status = data['status'] as String? ?? '';
    final photoUrl = data['photoURL'] as String?;
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
            // Avatar
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
            // Info
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
                      _SmallBadge(
                          label: roleLabel, color: roleColor),
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
            // Acciones
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _showProductDialog(context, null, null),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar productos.',
                  style: TextStyle(color: Color(0xFFC62828))),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
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
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              return _ProductCard(
                id: doc.id,
                data: doc.data(),
                onEdit: () => _showProductDialog(context, doc.id, doc.data()),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDialog(
      BuildContext context, String? id, Map<String, dynamic>? data) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ProductDialog(id: id, data: data),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.id, required this.data, required this.onEdit});
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
            '¿Seguro que deseas eliminar "${data['name'] ?? id}"?'),
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
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
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

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Sin nombre';
    final category = data['category'] as String? ?? '—';
    final rawPrice = data['price'];
    final price = rawPrice is num ? rawPrice.toDouble() : 0.0;
    final minQty = data['minOrderQty'];

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
            // Ícono categoría
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
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A2230))),
                  Text(category,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A94A6))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'RD\$ ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                            fontSize: 14),
                      ),
                      if (minQty != null) ...[
                        const SizedBox(width: 8),
                        Text('Min: $minQty uds',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF8A94A6))),
                      ],
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
    );
  }
}

// ─── Diálogo agregar / editar producto ────────────────────────────────────────
class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.id, this.data});
  final String? id;
  final Map<String, dynamic>? data;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _listPrice;
  late final TextEditingController _minQty;
  late final TextEditingController _stepQty;
  bool _saving = false;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _name = TextEditingController(text: d?['name'] as String? ?? '');
    _category = TextEditingController(text: d?['category'] as String? ?? '');
    final rawPrice = d?['price'];
    final rawList = d?['listPrice'];
    _price = TextEditingController(
        text: rawPrice is num ? rawPrice.toStringAsFixed(2) : '');
    _listPrice = TextEditingController(
        text: rawList is num ? rawList.toStringAsFixed(2) : '');
    _minQty = TextEditingController(
        text: (d?['minOrderQty'] ?? 1).toString());
    _stepQty = TextEditingController(
        text: (d?['stepQty'] ?? 1).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
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
      'category': _category.text.trim(),
      'price': double.parse(_price.text.trim()),
      'minOrderQty': int.tryParse(_minQty.text.trim()) ?? 1,
      'stepQty': int.tryParse(_stepQty.text.trim()) ?? 1,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final listPriceText = _listPrice.text.trim();
    if (listPriceText.isNotEmpty) {
      payload['listPrice'] = double.tryParse(listPriceText);
    }

    try {
      final col = FirebaseFirestore.instance.collection('products');
      if (_isEditing) {
        await col.doc(widget.id).update(payload);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        payload['imageAsset'] = 'assets/images/duralon_logo.png';
        await col.add(payload);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(
                  controller: _name,
                  label: 'Nombre',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                _Field(
                  controller: _category,
                  label: 'Categoría',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                _Field(
                  controller: _price,
                  label: 'Precio (RD\$)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
                _Field(
                  controller: _listPrice,
                  label: 'Precio anterior (opcional)',
                  keyboardType: TextInputType.number,
                ),
                _Field(
                  controller: _minQty,
                  label: 'Cantidad mínima',
                  keyboardType: TextInputType.number,
                ),
                _Field(
                  controller: _stepQty,
                  label: 'Multiplo de compra',
                  keyboardType: TextInputType.number,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
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
