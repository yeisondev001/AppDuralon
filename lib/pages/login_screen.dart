import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  static const Color _errorBg = Color(0xFFFFE8E8);
  static const Color _errorText = Color(0xFFB71C1C);
  String? _mensajeErrorLogin;
  bool _iniciandoConGoogle = false;
  bool _iniciandoConApple = false;
  final _authService = AuthService();

  static double _scaled(double v, double f, double min, double max) {
    return (v * f).clamp(min, max).toDouble();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _iniciarConGoogle() async {
    FocusScope.of(context).unfocus();
    if (_iniciandoConGoogle || _iniciandoConApple) return;

    setState(() => _iniciandoConGoogle = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      setState(() => _mensajeErrorLogin = null);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );

      if (userCredential.user != null) {
        _authService.ensureGoogleUserProfile(userCredential.user!).catchError(
          (Object e) => debugPrint('[AuthService] ensureGoogleUserProfile error: $e'),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'google-sign-in-no-id-token'
          ? 'Configuración incompleta. Contacta al soporte.'
          : 'Error de autenticación: ${e.message ?? e.code}';
      setState(() => _mensajeErrorLogin = msg);
    } catch (e) {
      final raw = e.toString();
      final msg = raw.contains('ApiException: 10')
          ? 'Google Sign-In no está autorizado en este dispositivo. '
              'El administrador debe registrar la huella SHA-1 en Firebase Console.'
          : raw.contains('ApiException: 16')
              ? 'Google Play Services no está disponible en este dispositivo.'
              : raw.contains('sign_in_canceled') || raw.contains('canceled')
                  ? null
                  : 'No se pudo iniciar con Google. Intenta de nuevo.';
      if (msg != null) {
        setState(() => _mensajeErrorLogin = msg);
      }
    } finally {
      if (mounted) {
        setState(() => _iniciandoConGoogle = false);
      }
    }
  }

  Future<void> _iniciarConApple() async {
    FocusScope.of(context).unfocus();
    if (_iniciandoConApple || _iniciandoConGoogle) return;

    setState(() => _iniciandoConApple = true);
    try {
      final userCredential = await _authService.signInWithApple();
      setState(() => _mensajeErrorLogin = null);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );

      if (userCredential.user != null) {
        _authService.ensureGoogleUserProfile(userCredential.user!).catchError(
          (Object e) => debugPrint('[AuthService] ensureGoogleUserProfile error: $e'),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _mensajeErrorLogin =
            'No se pudo iniciar con Apple: ${e.message ?? e.code}';
      });
    } catch (_) {
      setState(() {
        _mensajeErrorLogin = 'No se pudo iniciar con Apple. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _iniciandoConApple = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final width = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale = (width / 430).clamp(0.82, 1.2);
    final horizontalPadding = _scaled(width, 0.08, 20, 36);
    final logoSize = _scaled(width, 0.28, 110, 150);
    final buttonHeight = _scaled(58, scale, 52, 64);
    final titleSize = _scaled(32, scale, 25, 38);
    final guestTextSize = _scaled(19, scale, 16, 21);
    final topGap = _scaled(height, 0.14, 46, 108);
    final afterLogoGap = _scaled(height, 0.03, 16, 30);
    final sectionGap = _scaled(height, 0.028, 12, 24);

    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      resizeToAvoidBottomInset: true,
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      SizedBox(height: topGap),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: logoSize,
                            height: logoSize,
                            child: Image.asset(
                              'assets/images/duralon_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: afterLogoGap),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          '¡Bienvenido!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: _scaled(height, 0.04, 20, 40)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0,
                    horizontalPadding,
                    _scaled(height, 0.02, 12, 20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_mensajeErrorLogin != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
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
                                  _mensajeErrorLogin!,
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
                        SizedBox(height: _scaled(height, 0.018, 10, 14)),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: !_iniciandoConGoogle && !_iniciandoConApple
                              ? _iniciarConGoogle
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _iniciandoConGoogle
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryBlue,
                                    ),
                                  ),
                                )
                              : const FaIcon(
                                  FontAwesomeIcons.google,
                                  size: 20,
                                  color: Color(0xFF4285F4),
                                ),
                          label: Text(
                            _iniciandoConGoogle
                                ? 'Conectando...'
                                : 'Continuar con Google',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: _scaled(18, scale, 16, 20),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: _scaled(height, 0.016, 8, 12)),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: !_iniciandoConApple && !_iniciandoConGoogle
                              ? _iniciarConApple
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.textDark,
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: _iniciandoConApple
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textDark,
                                    ),
                                  ),
                                )
                              : const FaIcon(
                                  FontAwesomeIcons.apple,
                                  size: 22,
                                  color: AppColors.textDark,
                                ),
                          label: Text(
                            _iniciandoConApple
                                ? 'Conectando...'
                                : 'Continuar con Apple',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: _scaled(18, scale, 16, 20),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Text(
                        'Echar un vistazo como invitado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: guestTextSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Center(
                        child: IconButton(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              slideRightRoute<void>(
                                const HomeScreen(isGuestMode: true),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: _scaled(34, scale, 28, 40),
                            color: AppColors.primaryRed,
                          ),
                          tooltip: 'Continuar como invitado',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
