import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  // RNC + contraseña
  final _rncCtrl  = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _iniciandoRnc = false;

  String? _error;

  @override
  void dispose() {
    _rncCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Quita todo lo que no sea dígito (guiones, puntos, espacios).
  String _normalizeRnc(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  void _setError(String? msg) => setState(() => _error = msg);

  void _goHome({bool guest = false}) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      slideRightRoute<void>(HomeScreen(isGuestMode: guest)),
      (r) => false,
    );
  }

  // ── Login con RNC + contraseña ────────────────────────────────────────────────

  Future<void> _loginConRnc() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() { _iniciandoRnc = true; _error = null; });

    try {
      final rnc = _normalizeRnc(_rncCtrl.text.trim());
      final pass = _passCtrl.text;

      // 1. Buscar el correo del cliente por RNC en Firestore.
      final snap = await FirebaseFirestore.instance
          .collection('customers')
          .where('identificationNormalized', isEqualTo: rnc)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _setError(
          'RNC no encontrado. Contacta a ventas para registrarte.',
        );
        return;
      }

      final data = snap.docs.first.data();

      // 2. Verificar que la cuenta esté autorizada.
      final status = data['status'] as String?;
      if (status != 'activo') {
        _setError('Tu cuenta aún no está autorizada. Contacta a ventas para activarla.');
        return;
      }

      final correo = data['correo'] as String?;
      if (correo == null || correo.isEmpty) {
        _setError('Este RNC no tiene un correo asociado. Contacta soporte.');
        return;
      }

      // 3. Iniciar sesión con email + contraseña.
      await _authService.signIn(email: correo, password: pass);
      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      _setError(_msgFirebaseAuth(e.code));
    } catch (e) {
      _setError('Error inesperado. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _iniciandoRnc = false);
    }
  }

  String _msgFirebaseAuth(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña incorrecta. Intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      default:
        return 'Error de autenticación ($code).';
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _iniciandoRnc;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const SizedBox(height: 48),

            // ── Logo ───────────────────────────────────────────────────────
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/duralon_logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Bienvenido!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Inicia sesión para acceder a tus precios y pedidos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 36),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.primaryRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Formulario RNC + contraseña ────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // RNC
                  TextFormField(
                    controller: _rncCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !busy,
                    decoration: _inputDeco(
                      label: 'RNC',
                      hint: 'Ej: 131-12345-6',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (v) {
                      final n = _normalizeRnc(v ?? '');
                      if (n.isEmpty) return 'Ingresa tu RNC';
                      if (n.length < 9) return 'RNC inválido (mínimo 9 dígitos)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Contraseña
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.done,
                    enabled: !busy,
                    onFieldSubmitted: (_) => _loginConRnc(),
                    decoration: _inputDeco(
                      label: 'Contraseña',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botón Iniciar sesión
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: busy ? null : _loginConRnc,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _iniciandoRnc
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Invitado ───────────────────────────────────────────────────
            GestureDetector(
              onTap: busy ? null : () => _goHome(guest: true),
              child: const Text(
                'Echar un vistazo como invitado →',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
    );
  }
}
