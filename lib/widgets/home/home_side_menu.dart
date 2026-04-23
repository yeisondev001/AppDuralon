import 'package:flutter/material.dart';

class HomeSideMenu extends StatelessWidget {
  const HomeSideMenu({
    super.key,
    required this.onItemTap,
    required this.onLoginTap,
  });

  final ValueChanged<String> onItemTap;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 280,
        color: const Color(0xFFE5E5E5),
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
              onTap: () => onItemTap('Inicio'),
            ),
            _MenuItem(
              icon: Icons.grid_view_rounded,
              title: 'Catalogo',
              selected: true,
              onTap: () => onItemTap('Catalogo'),
            ),
            _MenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Mi perfil',
              onTap: () => onItemTap('Mi perfil'),
            ),
            _MenuItem(
              icon: Icons.local_offer_outlined,
              title: 'Ofertas',
              onTap: () => onItemTap('Ofertas'),
            ),
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Mis pedidos',
              onTap: () => onItemTap('Mis pedidos'),
            ),
            _MenuItem(
              icon: Icons.list_alt_rounded,
              title: 'Mis listas',
              onTap: () => onItemTap('Mis listas'),
            ),
            _MenuItem(
              icon: Icons.location_on_outlined,
              title: 'Mis direcciones',
              onTap: () => onItemTap('Mis direcciones'),
            ),
            _MenuItem(
              icon: Icons.credit_card_outlined,
              title: 'Metodos de pago',
              onTap: () => onItemTap('Metodos de pago'),
            ),
            _MenuItem(
              icon: Icons.support_agent_rounded,
              title: 'Soporte',
              onTap: () => onItemTap('Soporte'),
            ),
            const Spacer(),
            _MenuItem(
              icon: Icons.login_rounded,
              title: 'Iniciar sesion',
              onTap: onLoginTap,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Text(
                'Terminos y condiciones',
                style: TextStyle(
                  color: Color(0xFF7D8798),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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
