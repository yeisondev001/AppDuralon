import 'package:flutter/material.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/utils/show_terminos_bottom_sheet.dart';

class HomeSideMenu extends StatelessWidget {
  const HomeSideMenu({
    super.key,
    required this.onItemTap,
    this.onLoginTap,
    this.selectedItem = 'Inicio',
  });

  final ValueChanged<String> onItemTap;
  final VoidCallback? onLoginTap;
  final String selectedItem;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 14),
            _MenuItem(
              icon: Icons.home_outlined,
              title: 'Inicio',
              selected: selectedItem == 'Inicio',
              onTap: () => onItemTap('Inicio'),
            ),
            _MenuItem(
              icon: Icons.grid_view_rounded,
              title: 'Catalogo',
              selected: selectedItem == 'Catalogo',
              onTap: () => onItemTap('Catalogo'),
            ),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mi perfil',
              selected: selectedItem == 'Mi perfil',
              onTap: () => onItemTap('Mi perfil'),
            ),
            _MenuItem(
              icon: Icons.local_offer_outlined,
              title: 'Ofertas',
              selected: selectedItem == 'Ofertas',
              onTap: () => onItemTap('Ofertas'),
            ),
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Mis pedidos',
              selected: selectedItem == 'Mis pedidos',
              onTap: () => onItemTap('Mis pedidos'),
            ),
            _MenuItem(
              icon: Icons.list_alt_rounded,
              title: 'Mis listas',
              selected: selectedItem == 'Mis listas',
              onTap: () => onItemTap('Mis listas'),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              title: 'Mis direcciones',
              selected: selectedItem == 'Mis direcciones',
              onTap: () => onItemTap('Mis direcciones'),
            ),
            _MenuItem(
              icon: Icons.credit_card_outlined,
              title: 'Metodos de pago',
              selected: selectedItem == 'Metodos de pago',
              onTap: () => onItemTap('Metodos de pago'),
            ),
            _MenuItem(
              icon: Icons.support_agent_rounded,
              title: 'Soporte',
              selected: selectedItem == 'Soporte',
              onTap: () => onItemTap('Soporte'),
            ),
            const Spacer(),
            _MenuItem(
              icon: Icons.login_rounded,
              title: 'Iniciar sesion',
              onTap: onLoginTap ??
                  () {
                    Navigator.push<void>(
                      context,
                      slideRightRoute<void>(const LoginScreen()),
                    );
                  },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
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
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? const Color(0xFF0059B7) : const Color(0xFF5F6B7A);
    return Material(
      color: selected ? const Color(0xFFDDEEF9) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
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
