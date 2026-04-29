import 'package:app_duralon/models/order.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

class OrderService {
  static final _col = FirebaseFirestore.instance.collection('orders');

  static Future<String> createOrder(Order order) async {
    final ref = await _col.add(order.toFirestore());
    return ref.id;
  }

  static Stream<List<Order>> streamByCustomer(String customerId) {
    return _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Order.fromFirestore).toList());
  }

  static Stream<List<Order>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Order.fromFirestore).toList());
  }

  static Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _col.doc(orderId).update({
      'status':    status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
