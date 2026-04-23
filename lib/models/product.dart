class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageAsset,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageAsset;
}
