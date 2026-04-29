import 'package:app_duralon/models/customer_address.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressService {
  static CollectionReference<Map<String, dynamic>> _col(String uid) =>
      FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .collection('addresses');

  static Stream<List<CustomerAddress>> stream(String uid) {
    return _col(uid).snapshots().map((s) {
      final list = s.docs.map(CustomerAddress.fromFirestore).toList();
      list.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  static Future<void> add(String uid, CustomerAddress address) async {
    final batch = FirebaseFirestore.instance.batch();
    if (address.isDefault) await _clearDefault(uid, batch);
    final ref = _col(uid).doc();
    batch.set(ref, address.toFirestore());
    await batch.commit();
  }

  static Future<void> update(String uid, CustomerAddress address) async {
    final batch = FirebaseFirestore.instance.batch();
    if (address.isDefault) await _clearDefault(uid, batch, excludeId: address.id);
    batch.update(_col(uid).doc(address.id), {
      'label': address.label,
      'calle': address.calle,
      'ciudad': address.ciudad,
      'provincia': address.provincia,
      'referencia': address.referencia,
      if (address.lat != null) 'lat': address.lat,
      if (address.lng != null) 'lng': address.lng,
      'isDefault': address.isDefault,
    });
    await batch.commit();
  }

  static Future<void> delete(String uid, String addressId) async {
    await _col(uid).doc(addressId).delete();
  }

  static Future<void> setDefault(String uid, String addressId) async {
    final batch = FirebaseFirestore.instance.batch();
    await _clearDefault(uid, batch);
    batch.update(_col(uid).doc(addressId), {'isDefault': true});
    await batch.commit();
  }

  static Future<void> _clearDefault(
      String uid, WriteBatch batch, {String? excludeId}) async {
    final snap = await _col(uid).where('isDefault', isEqualTo: true).get();
    for (final doc in snap.docs) {
      if (doc.id == excludeId) continue;
      batch.update(doc.reference, {'isDefault': false});
    }
  }
}
