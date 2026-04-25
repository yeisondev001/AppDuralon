import 'package:cloud_firestore/cloud_firestore.dart';

class ProductWholesaleRule {
  const ProductWholesaleRule({
    required this.minOrderQty,
    required this.stepQty,
  });

  final int minOrderQty;
  final int stepQty;
}

class ProductRulesService {
  ProductRulesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ProductWholesaleRule?> getRuleByProductId(String productId) async {
    final snapshot = await _firestore.collection('products').doc(productId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final rawMin = data['minOrderQty'];
    final rawStep = data['stepQty'];
    final minOrderQty = rawMin is int ? rawMin : 0;
    final stepQty = rawStep is int ? rawStep : 1;

    if (minOrderQty <= 0) return null;
    return ProductWholesaleRule(
      minOrderQty: minOrderQty,
      stepQty: stepQty <= 0 ? 1 : stepQty,
    );
  }
}
