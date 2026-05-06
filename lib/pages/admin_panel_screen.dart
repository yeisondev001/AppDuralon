import 'package:app_duralon/pages/admin_panel/tabs/catalogos_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/ordenes_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/productos_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/pruebas_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/usuarios_tab.dart';
import 'package:app_duralon/styles/app_style.dart';
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2230),
          ),
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
          UsuariosTab(),
          CatalogosTab(),
          ProductosTab(),
          OrdenesTab(),
          PruebasTab(),
        ],
      ),
    );
  }
}
