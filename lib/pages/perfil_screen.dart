import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/styles/app_style.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // La pantalla se muestra de inmediato con los datos de Auth.
  // Firestore carga en segundo plano y actualiza cuando llega.
  bool _firestoreLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _customerData;
  String? _firestoreError;

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  Future<void> _loadFirestoreData() async {
    if (!mounted) return;
    setState(() {
      _firestoreLoading = true;
      _firestoreError = null;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _firestoreLoading = false);
      return;
    }

    try {
      // Tiempo límite de 10 s para no quedarse colgado.
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10)),
        FirebaseFirestore.instance
            .collection('customers')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10)),
      ]);
      if (!mounted) return;
      setState(() {
        _userData = results[0].data();
        _customerData = results[1].data();
        _firestoreLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _firestoreLoading = false;
        _firestoreError = 'No se pudieron cargar los datos adicionales.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2230),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E8EF)),
        ),
      ),
      body: user == null
          ? const Center(child: Text('No hay sesión activa.'))
          : RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: _loadFirestoreData,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  _AvatarHeader(user: user, userData: _userData),
                  const SizedBox(height: 20),
                  if (_firestoreError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFE65100),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _firestoreError!,
                              style: const TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadFirestoreData,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  _InfoCard(
                    title: 'Información de cuenta',
                    icon: Icons.manage_accounts_outlined,
                    trailing: _firestoreLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : null,
                    children: _buildCuentaRows(user, _userData),
                  ),
                  const SizedBox(height: 14),
                  if (!_firestoreLoading && _customerData != null)
                    _InfoCard(
                      title: 'Información de cliente',
                      icon: Icons.storefront_outlined,
                      children: _buildClienteRows(_userData, _customerData!),
                    ),
                ],
              ),
            ),
    );
  }

  /// Campos de la tarjeta "Información de cuenta" según el rol.
  List<Widget> _buildCuentaRows(User user, Map<String, dynamic>? data) {
    final role = data?['rol'] as String?;
    final esInterno = role == 'admin';

    return [
      // Todos ven su nombre y correo.
      _InfoRow(
        label: 'Nombre',
        value: data?['nombre'] as String? ?? user.displayName ?? '—',
      ),
      _InfoRow(
        label: 'Correo',
        value: data?['correo'] as String? ?? user.email ?? '—',
      ),
      _InfoRow(
        label: 'Miembro desde',
        value: _formatTimestamp(data?['creadoEn'] as Timestamp?),
      ),
      // Solo admin y vendedor ven los campos técnicos.
      if (esInterno) ...[
        _InfoRow(label: 'Rol', value: role ?? '—', isRole: true),
        _InfoRow(
          label: 'Estado',
          value: data?['estado'] as String? ?? '—',
          isStatus: true,
        ),
        _InfoRow(
          label: 'Proveedor',
          value: _providerLabel(data?['proveedorLogin'] as String?),
        ),
        _InfoRow(
          label: 'ID de usuario',
          value: user.uid,
          mono: true,
          small: true,
        ),
      ],
    ];
  }

  /// Campos de la tarjeta "Información de cliente" según el rol.
  List<Widget> _buildClienteRows(
    Map<String, dynamic>? userData,
    Map<String, dynamic> customer,
  ) {
    final role = userData?['rol'] as String?;
    final esInterno = role == 'admin';
    final taxpayerType = customer['tipoContribuyente'] as String?;
    final identification = customer['identificacion'] as String?;
    final identificationType = customer['tipoIdentificacion'] as String?;
    final fiscalAddress = customer['direccionFiscal'] as String?;

    return [
      _InfoRow(
        label: 'Nombre',
        value: customer['nombreCompleto'] as String? ?? '—',
      ),
      _InfoRow(
        label: 'Correo',
        value: customer['correo'] as String? ?? '—',
      ),
      _InfoRow(
        label: 'Tipo de cliente',
        value: _taxpayerTypeLabel(taxpayerType),
      ),
      _InfoRow(
        label: _identificationLabel(
          type: identificationType,
          taxpayerType: taxpayerType,
        ),
        value: (identification != null && identification.trim().isNotEmpty)
            ? identification
            : '—',
      ),
      _InfoRow(
        label: 'Dirección fiscal',
        value: (fiscalAddress != null && fiscalAddress.trim().isNotEmpty)
            ? fiscalAddress
            : '—',
      ),
      // Solo admin y vendedor ven estado, crédito e ID técnico.
      if (esInterno) ...[
        _InfoRow(
          label: 'Estado',
          value: customer['estado'] as String? ?? '—',
          isCustomerStatus: true,
        ),
        _InfoRow(
          label: 'Crédito habilitado',
          value: (customer['creditoHabilitado'] == true) ? 'Sí' : 'No',
        ),
        _InfoRow(
          label: 'Registrado',
          value: _formatTimestamp(customer['creadoEn'] as Timestamp?),
        ),
      ],
    ];
  }

  String _providerLabel(String? provider) {
    switch (provider) {
      case 'google':
        return 'Google';
      case 'email':
        return 'Correo y contraseña';
      default:
        return provider ?? '—';
    }
  }

  String _taxpayerTypeLabel(String? type) {
    switch (type) {
      case 'empresa':
        return 'Empresa';
      case 'zona_franca':
        return 'Zona Franca';
      case 'gubernamental':
        return 'Gubernamental';
      case 'persona_fisica':
        return 'Persona Física';
      default:
        return '—';
    }
  }

  String _identificationLabel({
    required String? type,
    required String? taxpayerType,
  }) {
    if (type == 'rnc') return 'RNC';
    if (type == 'cedula') return 'Cédula';
    if (taxpayerType == 'empresa' ||
        taxpayerType == 'zona_franca' ||
        taxpayerType == 'gubernamental') {
      return 'RNC';
    }
    if (taxpayerType == 'persona_fisica') return 'Cédula';
    return 'Identificación';
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate().toLocal();
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Avatar grande + nombre + rol ─────────────────────────────────────────────
class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.user, required this.userData});

  final User user;
  final Map<String, dynamic>? userData;

  @override
  Widget build(BuildContext context) {
    final name = userData?['nombre'] as String? ?? user.displayName ?? '';
    final email = userData?['correo'] as String? ?? user.email ?? '';
    final photoUrl = userData?['fotoUrl'] as String? ?? user.photoURL;
    final role = userData?['rol'] as String?;

    final initials = _initials(name, email);
    const roleLabels = {
      'cliente_minorista': 'Cliente Minorista',
      'cliente_distribuidor': 'Cliente Distribuidor',
      'cliente': 'Cliente',
      'admin': 'Administrador',
    };
    const roleColors = {
      'cliente_minorista': Color(0xFF1565C0),
      'cliente_distribuidor': Color(0xFF00838F),
      'cliente': Color(0xFF1565C0),
      'admin': Color(0xFFC62828),
    };
    final roleLabel = roleLabels[role] ?? role ?? '';
    final roleColor = roleColors[role] ?? const Color(0xFF546E7A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.25),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _InitialsWidget(initials: initials),
                    )
                  : _InitialsWidget(initials: initials),
            ),
          ),
          const SizedBox(height: 14),
          if (name.isNotEmpty)
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2230),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7685)),
            textAlign: TextAlign.center,
          ),
          if (role == 'admin' && roleLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: roleColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name, String email) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}

class _InitialsWidget extends StatelessWidget {
  const _InitialsWidget({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD6E4F0),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta de sección ───────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2230),
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing!],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF0F4)),
          ...children,
        ],
      ),
    );
  }
}

// ─── Fila de dato ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isRole = false,
    this.isStatus = false,
    this.isCustomerStatus = false,
    this.mono = false,
    this.small = false,
  });

  final String label;
  final String value;
  final bool isRole;
  final bool isStatus;
  final bool isCustomerStatus;
  final bool mono;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: _valueWidget()),
        ],
      ),
    );
  }

  Widget _valueWidget() {
    if (isRole) return _RoleBadge(role: value);
    if (isStatus) return _StatusBadge(status: value);
    if (isCustomerStatus) return _CustomerStatusBadge(status: value);

    return Text(
      value,
      style: TextStyle(
        fontSize: small ? 11 : 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A2230),
        fontFamily: mono ? 'monospace' : null,
      ),
    );
  }
}

// ─── Badges de rol, estado, estado-cliente ────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    const labels = {
      'cliente_minorista': 'Cliente Minorista',
      'cliente_distribuidor': 'Cliente Distribuidor',
      'cliente': 'Cliente',
      'admin': 'Administrador',
    };
    const colors = {
      'cliente_minorista': Color(0xFF1565C0),
      'cliente_distribuidor': Color(0xFF00838F),
      'cliente': Color(0xFF1565C0),
      'admin': Color(0xFFC62828),
    };
    final label = labels[role] ?? role;
    final color = colors[role] ?? const Color(0xFF546E7A);
    return _Badge(label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'activo'
        ? const Color(0xFF2E7D32)
        : const Color(0xFF9E9E9E);
    final label = status == 'activo' ? 'Activo' : status;
    return _Badge(label: label, color: color);
  }
}

class _CustomerStatusBadge extends StatelessWidget {
  const _CustomerStatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'activo' => const Color(0xFF2E7D32),
      'pendiente_validacion' => const Color(0xFFE65100),
      'suspendido' => const Color(0xFFC62828),
      _ => const Color(0xFF9E9E9E),
    };
    final label = switch (status) {
      'activo' => 'Activo',
      'pendiente_validacion' => 'Pendiente validación',
      'suspendido' => 'Suspendido',
      _ => status,
    };
    return _Badge(label: label, color: color);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
