import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/utils/show_quienes_somos_bottom_sheet.dart';
import 'package:app_duralon/utils/show_terminos_bottom_sheet.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Titulos de items del menu que requieren cuenta; en modo invitado se muestra el
/// dialogo para acceder a Duralon (mismo que carrito de invitado).
const Set<String> kSideMenuItemsRequiringAccount = {
  'Mi perfil',
  'Ofertas',
  'Mis pedidos',
  'Mis listas',
  'Mis direcciones',
  'Metodos de pago',
  'Soporte',
};

// ─── Colores y etiquetas por rol ──────────────────────────────────────────────
const _kRoleLabels = {
  'cliente': 'Cliente',
  'vendedor': 'Vendedor',
  'admin': 'Administrador',
};
const _kRoleColors = {
  'cliente': Color(0xFF1565C0),
  'vendedor': Color(0xFFE65100),
  'admin': Color(0xFFC62828),
};

class HomeSideMenu extends StatefulWidget {
  const HomeSideMenu({
    super.key,
    required this.onItemTap,
    this.onLoginTap,
    this.selectedItem = 'Inicio',
    this.showWholesaleRules = false,
    this.showAdminPanel = false,
  });

  final ValueChanged<String> onItemTap;
  final VoidCallback? onLoginTap;
  final String selectedItem;
  final bool showWholesaleRules;
  final bool showAdminPanel;

  @override
  State<HomeSideMenu> createState() => _HomeSideMenuState();
}

class _HomeSideMenuState extends State<HomeSideMenu> {
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role = doc.data()?['role'] as String?;
      if (mounted) setState(() => _role = role);
    } catch (_) {}
  }

  Future<void> _signOut(BuildContext context) async {
    // En móvil: cerrar sesión en Google Y revocar acceso para que
    // aparezca el selector de cuenta en el próximo login.
    // En web: Google Sign-In no se inicializa, solo cerramos Firebase.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        // Si disconnect falla (ej. no hay sesión Google activa), ignorar.
      }
    }
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      slideRightRoute<void>(const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    return SafeArea(
      child: Container(
        width: 280,
        color: const Color(0xFFF5F5F5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Image.asset(
                'assets/images/duralon_logo.png',
                width: 84,
                height: 84,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),

            // ── Encabezado de usuario ──────────────────────────────────────────
            _UserHeader(user: user, role: _role),
            const SizedBox(height: 8),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 6),

            // ── Ítems de navegación ───────────────────────────────────────────
            _MenuItem(
              icon: Icons.home_outlined,
              title: 'Inicio',
              selected: widget.selectedItem == 'Inicio',
              onTap: () => widget.onItemTap('Inicio'),
            ),
            _MenuItem(
              icon: Icons.grid_view_rounded,
              title: 'Catalogo',
              selected: widget.selectedItem == 'Catalogo',
              onTap: () => widget.onItemTap('Catalogo'),
            ),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mi perfil',
              selected: widget.selectedItem == 'Mi perfil',
              onTap: () => widget.onItemTap('Mi perfil'),
            ),
            _MenuItem(
              icon: Icons.local_offer_outlined,
              title: 'Ofertas',
              selected: widget.selectedItem == 'Ofertas',
              onTap: () => widget.onItemTap('Ofertas'),
            ),
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Mis pedidos',
              selected: widget.selectedItem == 'Mis pedidos',
              onTap: () => widget.onItemTap('Mis pedidos'),
            ),
            _MenuItem(
              icon: Icons.list_alt_rounded,
              title: 'Mis listas',
              selected: widget.selectedItem == 'Mis listas',
              onTap: () => widget.onItemTap('Mis listas'),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              title: 'Mis direcciones',
              selected: widget.selectedItem == 'Mis direcciones',
              onTap: () => widget.onItemTap('Mis direcciones'),
            ),
            _MenuItem(
              icon: Icons.credit_card_outlined,
              title: 'Metodos de pago',
              selected: widget.selectedItem == 'Metodos de pago',
              onTap: () => widget.onItemTap('Metodos de pago'),
            ),
            _MenuItem(
              icon: Icons.support_agent_rounded,
              title: 'Soporte',
              selected: widget.selectedItem == 'Soporte',
              onTap: () => widget.onItemTap('Soporte'),
            ),
            if (widget.showWholesaleRules)
              _MenuItem(
                icon: Icons.tune_rounded,
                title: 'Reglas mayoristas',
                selected: widget.selectedItem == 'Reglas mayoristas',
                onTap: () => widget.onItemTap('Reglas mayoristas'),
              ),
            if (widget.showAdminPanel) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Divider(height: 1, color: Color(0xFFE0E0E0)),
              ),
              _MenuItem(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Panel de administración',
                selected: widget.selectedItem == 'Panel de administración',
                onTap: () => widget.onItemTap('Panel de administración'),
                textColor: const Color(0xFFC62828),
              ),
            ],

            const Spacer(),

            // ── Botón inferior: cerrar/iniciar sesión ─────────────────────────
            if (isLoggedIn)
              _MenuItem(
                icon: Icons.logout_rounded,
                title: 'Cerrar sesión',
                onTap: () => _signOut(context),
                textColor: const Color(0xFFC62828),
              )
            else
              _MenuItem(
                icon: Icons.login_rounded,
                title: 'Iniciar sesion',
                onTap: widget.onLoginTap ??
                    () {
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const LoginScreen()),
                      );
                    },
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showTerminosYCondicionesBottomSheet(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Términos y condiciones',
                      style: TextStyle(
                        color: Color(0xFF7D8798),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showQuienesSomosBottomSheet(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Quiénes somos',
                      style: TextStyle(
                        color: Color(0xFF7D8798),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Encabezado con avatar, nombre, correo y badge de rol ─────────────────────
class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user, required this.role});

  final User? user;
  final String? role;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Text(
          'Modo invitado',
          style: TextStyle(
            color: Color(0xFF9AA3AF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final displayName = user!.displayName?.trim();
    final email = user!.email ?? '';
    final photoUrl = user!.photoURL;
    final initials = _initials(displayName, email);

    final roleLabel = _kRoleLabels[role] ?? role ?? '';
    final roleColor = _kRoleColors[role] ?? const Color(0xFF546E7A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Avatar circular
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFD6E4F0),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayName != null && displayName.isNotEmpty)
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2230),
                    ),
                  ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7685),
                  ),
                ),
                if (roleLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name, String email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
}

// ─── Ítem de menú ──────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ??
        (selected ? const Color(0xFF0059B7) : const Color(0xFF5F6B7A));
    return Material(
      color: selected ? const Color(0xFFDDEEF9) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
