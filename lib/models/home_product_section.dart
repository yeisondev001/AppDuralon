import 'package:app_duralon/models/product.dart';

class HomeProductSection {
  const HomeProductSection({
    required this.categoryId,
    required this.title,
    this.titleEn,
    this.titleFr,
    required this.subtypes,
    required this.previewProducts,
  });

  final String categoryId;
  final String title;
  final String? titleEn;
  final String? titleFr;
  final List<String> subtypes;
  final List<Product> previewProducts;

  String titleFor(String lang) {
    if (lang == 'en' && titleEn?.isNotEmpty == true) return titleEn!;
    if (lang == 'fr' && titleFr?.isNotEmpty == true) return titleFr!;
    return title;
  }
}
