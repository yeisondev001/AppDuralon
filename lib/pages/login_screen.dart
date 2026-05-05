import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/config/app_locale.dart';
import 'package:app_duralon/pages/crear_cuenta_screen.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_flow.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/pages/recuperar_cuenta_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:app_duralon/widgets/language_picker.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _errorBg = Color(0xFFFFE8E8);
  static const Color _errorText = Color(0xFFB71C1C);

  final _formKey = GlobalKey<FormState>();
  final _rncController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String? _errorMsg;
  bool _iniciando = false;
  bool _obscurePassword = true;

  static double _scaled(double v, double f, double min, double max) =>
      (v * f).clamp(min, max).toDouble();

  @override
  void dispose() {
    _rncController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _iniciando = true;
      _errorMsg = null;
    });

    try {
      final credential = await _authService.signInWithRnc(
        rnc: _rncController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      final user = credential.user;
      if (user == null) return;

      // Verifica onboarding solo si el proveedor es Google
      final isGoogle = user.providerData
          .any((p) => p.providerId == 'google.com');
      if (isGoogle) {
        final needsOnboarding =
            await _authService.needsGoogleOnboarding(user);
        if (!mounted) return;
        if (needsOnboarding) {
          Navigator.pushAndRemoveUntil<void>(
            context,
            slideRightRoute<void>(const OnboardingFlow()),
            (route) => false,
          );
          return;
        }
      }

      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'rnc-not-found':
          msg = 'No se encontró una cuenta con ese RNC o cédula.';
        case 'rnc-no-email':
          msg = 'Error en la cuenta. Contacta al soporte.';
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Contraseña incorrecta.';
        case 'user-disabled':
          msg = 'Esta cuenta ha sido desactivada.';
        case 'too-many-requests':
          msg = 'Demasiados intentos. Intenta más tarde.';
        default:
          msg = e.message ?? 'Error al iniciar sesión.';
      }
      setState(() => _errorMsg = msg);
    } catch (_) {
      setState(() => _errorMsg = 'Error al iniciar sesión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final width = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale = (width / 430).clamp(0.82, 1.2);
    final padH = _scaled(width, 0.08, 20, 36);
    final logoSize = _scaled(width, 0.24, 90, 130);
    final topGap = _scaled(height, 0.08, 30, 70);
    final btnH = _scaled(56, scale, 50, 62);
    final titleSize = _scaled(30, scale, 24, 36);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: padH),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                children: [
                  SizedBox(height: topGap),

                  // Logo
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/duralon_logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: _scaled(height, 0.025, 14, 24)),

                  // Título
                  Text(
                    LocaleScope.tr(context, 'welcome'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: _scaled(height, 0.04, 22, 40)),

                  // Error
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryRed.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.primaryRed.withValues(alpha: 0.85),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: TextStyle(
                                color: _errorText,
                                fontSize: _scaled(15, scale, 13, 16),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Campo RNC / Cédula
                  TextFormField(
                    controller: _rncController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    enabled: !_iniciando,
                    decoration: InputDecoration(
                      labelText: LocaleScope.tr(context, 'rnc_label'),
                      hintText: LocaleScope.tr(context, 'rnc_hint'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? LocaleScope.tr(context, 'rnc_required')
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Campo Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _iniciando ? null : _iniciarSesion(),
                    enabled: !_iniciando,
                    decoration: InputDecoration(
                      labelText: LocaleScope.tr(context, 'password_label'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? LocaleScope.tr(context, 'password_required')
                        : null,
                  ),
                  const SizedBox(height: 6),

                  // Olvidé contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const RecuperarCuentaScreen()),
                      ),
                      child: Text(
                        LocaleScope.tr(context, 'forgot_password'),
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: _scaled(14, scale, 12, 15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _scaled(height, 0.012, 8, 14)),

                  // Botón Iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    height: btnH,
                    child: FilledButton(
                      onPressed: _iniciando ? null : _iniciarSesion,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _iniciando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              LocaleScope.tr(context, 'login_button'),
                              style: TextStyle(
                                fontSize: _scaled(17, scale, 15, 19),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: _scaled(height, 0.025, 14, 24)),

                  // Crear cuenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        LocaleScope.tr(context, 'no_account'),
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: _scaled(15, scale, 13, 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push<void>(
                          context,
                          slideRightRoute<void>(const CrearCuentaScreen()),
                        ),
                        child: Text(
                          LocaleScope.tr(context, 'create_account'),
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: _scaled(15, scale, 13, 16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Separador
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: _scaled(height, 0.018, 10, 18)),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: _scaled(14, scale, 12, 15),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                  // Continuar como invitado
                  Text(
                    LocaleScope.tr(context, 'browse_guest'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: _scaled(17, scale, 15, 19),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        slideRightRoute<void>(
                            const HomeScreen(isGuestMode: true)),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: _scaled(34, scale, 28, 40),
                        color: AppColors.primaryRed,
                      ),
                      tooltip: LocaleScope.tr(context, 'continue_guest'),
                    ),
                  ),
                  SizedBox(height: _scaled(height, 0.02, 12, 20)),
                ],
              ),
            ),

            // Selector de idioma: esquina superior izquierda
            const Positioned(
              top: 4,
              left: 4,
              child: LanguagePicker(),
            ),
          ],
        ),
      ),
    );
  }
}
