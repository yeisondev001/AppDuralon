import 'package:app_duralon/pages/admin_panel/widgets/admin_small_badge.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  final _authService = AuthService();

  Future<void> _mostrarDialogoCrearCliente() async {
    final rncCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool cargando = false;
    bool passVisible = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text(
            'Crear cliente',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: rncCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'RNC',
                    hintText: '9 dígitos',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el RNC';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre / Empresa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: !passVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        passVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setLocal(() => passVisible = !passVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: cargando ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: cargando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => cargando = true);
                      try {
                        await _authService.crearClienteConRnc(
                          rnc: rncCtrl.text.trim(),
                          nombre: nombreCtrl.text.trim(),
                          password: passCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cliente creado correctamente.'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      } on DuplicateRncException {
                        setLocal(() => cargando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ya existe un cliente con ese RNC.'),
                            backgroundColor: Color(0xFFC62828),
                          ),
                        );
                      } on InvalidRncException {
                        setLocal(() => cargando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('RNC inválido.'),
                            backgroundColor: Color(0xFFC62828),
                          ),
                        );
                      } catch (e) {
                        setLocal(() => cargando = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: const Color(0xFFC62828),
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearCliente,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(
          'Crear cliente',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar usuarios.',
                style: TextStyle(color: Color(0xFFC62828)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final uid = docs[i].id;
              return _UserCard(uid: uid, data: data);
            },
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.uid, required this.data});
  final String uid;
  final Map<String, dynamic> data;

  static const _roles = ['cliente_minorista', 'cliente_distribuidor', 'admin'];
  static const _roleColors = {
    'cliente_minorista': Color(0xFF1565C0),
    'cliente_distribuidor': Color(0xFF00838F),
    'cliente': Color(0xFF1565C0), // retrocompat
    'admin': Color(0xFFC62828),
  };
  static const _roleLabels = {
    'cliente_minorista': 'Cliente Minorista',
    'cliente_distribuidor': 'Cliente Distribuidor',
    'cliente': 'Cliente', // retrocompat
    'admin': 'Administrador',
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
              'Rol cambiado a "${_roleLabels[newRole] ?? newRole}" correctamente.',
            ),
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
              foregroundColor: const Color(0xFFC62828),
            ),
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
              leading: CircleAvatar(radius: 8, backgroundColor: color),
              title: Text(
                _roleLabels[role] ?? role,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
                      (name.isNotEmpty
                              ? name[0]
                              : email.isNotEmpty
                              ? email[0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A2230),
                      ),
                    ),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7685),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      AdminSmallBadge(label: roleLabel, color: roleColor),
                      if (status.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        AdminSmallBadge(
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
                  icon: const Icon(
                    Icons.manage_accounts_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () => _showRoleDialog(context),
                ),
                IconButton(
                  tooltip: 'Eliminar usuario',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFC62828),
                  ),
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
