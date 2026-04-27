import 'package:flutter/material.dart';

/// Icono por grupo del catálogo (mismas claves que [kCatalogHogar] y [kCatalogIndustrial]).
const Map<String, IconData> kCatalogGroupIcons = <String, IconData>{
  'Cocina': Icons.restaurant_menu_outlined,
  'Artículos del Hogar': Icons.home_work_outlined,
  'Mascotas': Icons.pets,
  'Jardinería': Icons.park_outlined,
  'Muebles': Icons.weekend_outlined,
  'Infantil': Icons.child_care_outlined,
  'Industrial': Icons.precision_manufacturing_outlined,
};

IconData iconForCatalogGroup(String groupTitle) =>
    kCatalogGroupIcons[groupTitle] ?? Icons.category_outlined;
