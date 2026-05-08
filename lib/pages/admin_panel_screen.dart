import 'package:app_duralon/pages/admin_panel/tabs/catalogos_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/clientes_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/ordenes_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/productos_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/pruebas_tab.dart';
import 'package:app_duralon/pages/admin_panel/tabs/usuarios_tab.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

/// [AdminPanelScreen] es la pantalla principal del panel de administración.
/// Sirve como contenedor para navegar entre las diferentes secciones administrativas
/// (usuarios, clientes, catálogos, productos, etc.) utilizando pestañas (Tabs).
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  /// Controlador para gestionar el estado y la animación de las pestañas.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    // Inicializa el controlador con 6 pestañas.
    // 'vsync: this' permite que las animaciones estén sincronizadas con los frames del widget, optimizando recursos.
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    // Es importante liberar (dispose) el controlador cuando el widget se destruye 
    // para evitar fugas de memoria (memory leaks).
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo general de la pantalla
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Botón en la parte superior izquierda para regresar a la pantalla anterior
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
        // Barra de pestañas (TabBar) que se muestra debajo del título del AppBar
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryBlue, // Color del texto e icono seleccionados
          unselectedLabelColor: const Color(0xFF8A94A6), // Color para pestañas inactivas
          indicatorColor: AppColors.primaryBlue, // Línea indicadora bajo la pestaña activa
          tabs: const [
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Usuarios'),
            Tab(icon: Icon(Icons.business_outlined), text: 'Clientes'),
            Tab(icon: Icon(Icons.category_outlined), text: 'Catálogos'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Órdenes'),
            Tab(icon: Icon(Icons.bug_report_outlined), text: 'Pruebas'),
          ],
        ),
      ),
      // TabBarView muestra el contenido correspondiente a la pestaña seleccionada
      body: TabBarView(
        controller: _tabs, // Usa el mismo controlador para sincronizarse con la barra de pestañas
        children: const [
          UsuariosTab(),
          ClientesTab(),
          CatalogosTab(),
          ProductosTab(),
          OrdenesTab(),
          PruebasTab(),
        ],
      ),
    );
  }
}
