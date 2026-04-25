import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DuplicateRncException implements Exception {}

class InvalidRncException implements Exception {}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> registerWholesaleCustomer({
    required String email,
    required String password,
    required String rnc,
    required String taxpayerType,
    required String legalName,
    required String contactName,
    required String phone,
    required String fiscalAddress,
  }) async {
    final normalizedRnc = _normalizeRnc(rnc);
    if (!isValidDominicanRnc(normalizedRnc)) {
      throw InvalidRncException();
    }
    final rncAlreadyInUse = await _isRncAlreadyRegistered(normalizedRnc);
    if (rncAlreadyInUse) {
      throw DuplicateRncException();
    }
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'No fue posible crear el usuario.',
      );
    }

    final customerRef = _firestore.collection('customers').doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(customerRef, {
      'customerId': user.uid,
      'rnc': rnc.trim(),
      'rncNormalized': normalizedRnc,
      'taxpayerType': taxpayerType,
      'legalName': legalName.trim(),
      'contactName': contactName.trim(),
      'phone': phone.trim(),
      'billingEmail': email.trim(),
      'fiscalAddress': fiscalAddress.trim(),
      'status': 'pendiente_validacion',
      'creditEnabled': false,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(userRef, {
      'uid': user.uid,
      'customerId': user.uid,
      'email': email.trim(),
      'role': 'owner',
      'status': 'activo',
      'createdAt': now,
      'updatedAt': now,
    });
    await batch.commit();
  }

  String _normalizeRnc(String rnc) {
    return rnc.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<bool> _isRncAlreadyRegistered(String normalizedRnc) async {
    final snapshot = await _firestore
        .collection('customers')
        .where('rncNormalized', isEqualTo: normalizedRnc)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static bool isValidDominicanRnc(String rawRnc) {
    final rnc = rawRnc.replaceAll(RegExp(r'[^0-9]'), '');
    if (rnc.length != 9) return false;
    const weights = [7, 9, 8, 6, 5, 4, 3, 2];
    var total = 0;
    for (var i = 0; i < 8; i++) {
      total += int.parse(rnc[i]) * weights[i];
    }
    final remainder = total % 11;
    final verifier = remainder <= 1 ? 0 : 11 - remainder;
    return verifier == int.parse(rnc[8]);
  }
}
