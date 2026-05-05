import 'package:app_duralon/config/app_strings.dart';
import 'package:app_duralon/services/locale_service.dart';
import 'package:app_duralon/widgets/language_selector.dart';
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
  static const Color _errorBg   = Color(0xFFFFE8E8);
  static const Color _errorText = Color(0xFFB71C1C);

  final _authService  = AuthService();
  final _rncCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  String? _mensajeError;
  bool _iniciandoRnc = false;
  bool _passVisible  = false;

  static double _scaled(double v, double f, double min, double max) =>
      (v * f).clamp(min, max).toDouble();

  @override
  void dispose() {
    _rncCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── RNC + contraseña ──────────────────────────────────────────────────────

  Future<void> _iniciarConRnc() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_iniciandoRnc) return;
    setState(() { _iniciandoRnc = true; _mensajeError = null; });
    try {
      await _authService.signInWithRnc(
        rnc:      _rncCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      _goHome(const HomeScreen(isGuestMode: false));
    } on UserNotActiveException {
      _setError(S.errInactive);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found'     => S.errNotFound,
        'wrong-password'     => S.errWrongPass,
        'invalid-credential' => S.errBadCred,
        'too-many-requests'  => S.errTooMany,
        _ => 'Error: ${e.message ?? e.code}',
      };
      _setError(msg);
    } catch (_) {
      _setError(S.errGeneric);
    } finally {
      if (mounted) setState(() => _iniciandoRnc = false);
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() => _mensajeError = msg);
  }

  void _goHome(Widget page) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      slideRightRoute<void>(page),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w      = MediaQuery.sizeOf(context).width;
    final h      = MediaQuery.sizeOf(context).height;
    final width  = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale  = (width / 430).clamp(0.82, 1.2);
    final hp     = _scaled(width, 0.08, 20, 36);
    final logoSz = _scaled(width, 0.26, 100, 140);
    final btnH   = _scaled(58, scale, 52, 64);
    final topGap = _scaled(height, 0.1, 36, 90);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.instance,
      builder: (context, lang, child) => Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: hp),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              // ── Selector de idioma (esquina superior derecha) ─────
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: const LanguageSelectorButton(onSurface: true),
              ),

              SizedBox(height: topGap - 8),

              // Logo
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: logoSz,
                    height: logoSz,
                    child: Image.asset('assets/images/duralon_logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                S.welcome,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: _scaled(30, scale, 24, 36),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: _scaled(height, 0.04, 20, 44)),

              // Error
              if (_mensajeError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: AppColors.primaryRed.withValues(alpha: 0.85), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mensajeError!,
                          style: TextStyle(
                            color: _errorText,
                            fontSize: _scaled(14, scale, 12, 16),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Campos RNC + contraseña ───────────────────────────────────
              TextFormField(
                controller: _rncCtrl,
                keyboardType: TextInputType.number,
                maxLength: 11,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: S.rncLabel,
                  hintText: S.rncHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return S.rncEmpty;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: !_passVisible,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: S.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _passVisible = !_passVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return S.passwordEmpty;
                  return null;
                },
                onFieldSubmitted: (_) => _iniciarConRnc(),
              ),
              const SizedBox(height: 16),

              // Botón ingresar
              SizedBox(
                width: double.infinity,
                height: btnH,
                child: FilledButton(
                  onPressed: _iniciandoRnc ? null : _iniciarConRnc,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _iniciandoRnc
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          S.loginBtn,
                          style: TextStyle(
                            fontSize: _scaled(18, scale, 16, 20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              SizedBox(height: _scaled(height, 0.05, 24, 40)),
            ],
          ),
        ),
      ),
    ));
  }
}
