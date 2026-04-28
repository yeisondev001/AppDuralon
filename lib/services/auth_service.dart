import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';


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
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // idToken: identifica al usuario → necesario para Firebase Auth.
    // authentication es síncrono en 7.x (no requiere await).
    final String? idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-no-id-token',
        message: 'Google Sign-In no devolvió un idToken. '
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
      'role': 'cliente_minorista',
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
