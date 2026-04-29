import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DuplicateRncException implements Exception {}

class InvalidRncException implements Exception {}

class DuplicateIdentificationException implements Exception {}

class InvalidIdentificationException implements Exception {}

class InvalidTaxpayerTypeException implements Exception {}

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
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

  Future<UserCredential> signInWithGoogle() async {
    // ── WEB ──────────────────────────────────────────────────────────────────
    // En web, GoogleSignIn.instance.supportsAuthenticate() es false.
    // Firebase maneja el popup completo internamente.
    if (kIsWeb) {
      // prompt: 'select_account' fuerza el selector de cuentas de Google
      // aunque el navegador ya tenga una sesión activa.
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return _firebaseAuth.signInWithPopup(provider);
    }

    // ── MÓVIL (Android / iOS) ─────────────────────────────────────────────
    // google_sign_in 7.x: authenticate() muestra el selector de cuenta.
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    // idToken: identifica al usuario → necesario para Firebase Auth.
    // authentication es síncrono en 7.x (no requiere await).
    final String? idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-no-id-token',
        message:
            'Google Sign-In no devolvió un idToken. '
            'Verifica que el serverClientId esté configurado en main.dart '
            'con el "Web client ID" de tu proyecto Firebase.',
      );
    }

    // accessToken: necesario para llamadas a APIs de Google (opcional para Firebase).
    // En 7.x se obtiene con authorizeScopes (puede omitirse si solo necesitas Auth).
    String? accessToken;
    try {
      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);
      accessToken = clientAuth.accessToken;
    } catch (_) {
      // Si la autorización de scopes falla, continuamos solo con idToken.
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final provider = OAuthProvider('apple.com');
    provider.addScope('email');
    provider.addScope('name');

    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(provider);
    }

    return _firebaseAuth.signInWithProvider(provider);
  }

  // Crea los documentos de Firestore la primera vez que el usuario inicia
  // sesión con Google. En logins posteriores detecta que ya existen y no hace nada.
  Future<void> ensureGoogleUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();

    // Si el documento ya existe, el usuario ya tiene perfil — no sobreescribir.
    if (snapshot.exists) return;

    final now = FieldValue.serverTimestamp();
    final customerRef = _firestore.collection('customers').doc(user.uid);
    final batch = _firestore.batch();

    batch.set(userRef, {
      'uid': user.uid,
      'customerId': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'role': 'cliente_minorista',
      'status': 'activo',
      'loginProvider': 'google',
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(customerRef, {
      'customerId': user.uid,
      'contactName': user.displayName ?? '',
      'billingEmail': user.email ?? '',
      'status': 'pendiente_validacion',
      'creditEnabled': false,
      'loginProvider': 'google',
      'createdAt': now,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<bool> needsGoogleOnboarding(User user) async {
    await ensureGoogleUserProfile(user);
    final customerDoc = await _firestore
        .collection('customers')
        .doc(user.uid)
        .get();
    final data = customerDoc.data();
    if (data == null) return true;

    final taxpayerType = (data['taxpayerType'] as String?)?.trim() ?? '';
    final fullName = (data['fullName'] as String?)?.trim() ?? '';
    final identification =
        (data['identificationNormalized'] as String?)?.trim() ?? '';
    final city = (data['city'] as String?)?.trim() ?? '';
    final country = (data['country'] as String?)?.trim() ?? '';
    final phone = (data['phone'] as String?)?.trim() ?? '';
    final fiscalAddress = (data['fiscalAddress'] as String?)?.trim() ?? '';

    if (taxpayerType.isEmpty ||
        fullName.isEmpty ||
        identification.isEmpty ||
        city.isEmpty ||
        country.isEmpty ||
        phone.isEmpty ||
        fiscalAddress.isEmpty) {
      return true;
    }

    final requiresRnc = _taxpayerTypeRequiresRnc(taxpayerType);
    if (requiresRnc == null) return true;
    if (requiresRnc) {
      return identification.length != 9 || !isValidDominicanRnc(identification);
    }
    return identification.length != 11 ||
        !_isValidDominicanCedula(identification);
  }

  Future<void> completeGoogleCustomerOnboarding({
    required User user,
    required String taxpayerType,
    required String fullName,
    required String identification,
    required String city,
    required String country,
    required String phone,
    required String fiscalAddress,
  }) async {
    final normalizedType = taxpayerType.trim();
    final requiresRnc = _taxpayerTypeRequiresRnc(normalizedType);
    if (requiresRnc == null) throw InvalidTaxpayerTypeException();

    final normalizedIdentification = _normalizeDigits(identification);
    final isValidIdentification = requiresRnc
        ? normalizedIdentification.length == 9 &&
              isValidDominicanRnc(normalizedIdentification)
        : normalizedIdentification.length == 11 &&
              _isValidDominicanCedula(normalizedIdentification);
    if (!isValidIdentification) {
      throw InvalidIdentificationException();
    }

    final idUsedByOtherUser = await _isIdentificationUsedByOtherUser(
      normalizedIdentification: normalizedIdentification,
      uid: user.uid,
    );
    if (idUsedByOtherUser) {
      throw DuplicateIdentificationException();
    }

    final customerRef = _firestore.collection('customers').doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.set(customerRef, {
      'customerId': user.uid,
      'identification': identification.trim(),
      'identificationNormalized': normalizedIdentification,
      'identificationType': requiresRnc ? 'rnc' : 'cedula',
      if (requiresRnc) 'rnc': identification.trim(),
      if (requiresRnc) 'rncNormalized': normalizedIdentification,
      if (!requiresRnc) 'cedula': identification.trim(),
      if (!requiresRnc) 'cedulaNormalized': normalizedIdentification,
      'taxpayerType': normalizedType,
      'fullName': fullName.trim(),
      'legalName': fullName.trim(),
      'contactName': fullName.trim(),
      'phone': phone.trim(),
      'billingEmail': (user.email ?? '').trim(),
      'fiscalAddress': fiscalAddress.trim(),
      'city': city.trim(),
      'country': country.trim(),
      'status': 'pendiente_validacion',
      'creditEnabled': false,
      'loginProvider': 'google',
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'uid': user.uid,
      'customerId': user.uid,
      'email': (user.email ?? '').trim(),
      'displayName': fullName.trim(),
      'photoURL': user.photoURL ?? '',
      'role': 'cliente_minorista',
      'status': 'activo',
      'loginProvider': 'google',
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> registerWholesaleCustomer({
    required String email,
    required String password,
    required String identification,
    required String taxpayerType,
    required String fullName,
    required String city,
    required String country,
    required String phone,
    required String fiscalAddress,
  }) async {
    final normalizedIdentification = _normalizeDigits(identification);
    final idType = _identificationType(normalizedIdentification);
    if (idType == null) {
      throw InvalidIdentificationException();
    }
    final idAlreadyInUse = await _isIdentificationAlreadyRegistered(
      normalizedIdentification,
    );
    if (idAlreadyInUse) {
      throw DuplicateIdentificationException();
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
      'identification': identification.trim(),
      'identificationNormalized': normalizedIdentification,
      'identificationType': idType,
      if (idType == 'rnc') 'rnc': identification.trim(),
      if (idType == 'rnc') 'rncNormalized': normalizedIdentification,
      if (idType == 'cedula') 'cedula': identification.trim(),
      if (idType == 'cedula') 'cedulaNormalized': normalizedIdentification,
      'taxpayerType': taxpayerType,
      'fullName': fullName.trim(),
      // Compatibilidad con el modelo anterior:
      'legalName': fullName.trim(),
      'contactName': fullName.trim(),
      'phone': phone.trim(),
      'billingEmail': email.trim(),
      'fiscalAddress': fiscalAddress.trim(),
      'city': city.trim(),
      'country': country.trim(),
      'status': 'pendiente_validacion',
      'creditEnabled': false,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(userRef, {
      'uid': user.uid,
      'customerId': user.uid,
      'email': email.trim(),
      'role': 'cliente_minorista',
      'status': 'activo',
      'createdAt': now,
      'updatedAt': now,
    });
    await batch.commit();
  }

  String _normalizeDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String? _identificationType(String normalized) {
    if (normalized.length == 9 && isValidDominicanRnc(normalized)) {
      return 'rnc';
    }
    if (normalized.length == 11 && _isValidDominicanCedula(normalized)) {
      return 'cedula';
    }
    return null;
  }

  Future<bool> _isIdentificationAlreadyRegistered(
    String normalizedIdentification,
  ) async {
    final snapshot = await _firestore
        .collection('customers')
        .where('identificationNormalized', isEqualTo: normalizedIdentification)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> _isIdentificationUsedByOtherUser({
    required String normalizedIdentification,
    required String uid,
  }) async {
    final snapshot = await _firestore
        .collection('customers')
        .where('identificationNormalized', isEqualTo: normalizedIdentification)
        .limit(5)
        .get();
    return snapshot.docs.any((doc) => doc.id != uid);
  }

  bool? _taxpayerTypeRequiresRnc(String taxpayerType) {
    switch (taxpayerType) {
      case 'empresa':
      case 'zona_franca':
      case 'gubernamental':
        return true;
      case 'persona_fisica':
        return false;
      default:
        return null;
    }
  }

  bool _isValidDominicanCedula(String normalizedCedula) {
    if (normalizedCedula.length != 11) return false;
    final digits = normalizedCedula.split('').map(int.parse).toList();
    const weights = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final product = digits[i] * weights[i];
      sum += product > 9 ? product - 9 : product;
    }
    final verifier = (10 - (sum % 10)) % 10;
    return verifier == digits[10];
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
