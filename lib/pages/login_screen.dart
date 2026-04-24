import 'package:flutter/material.dart';
import 'package:app_duralon/pages/crear_cuenta_screen.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/pages/iniciar_session_screen.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static double _scaled(double value, double factor, double min, double max) {
    return (value * factor).clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final scale = (width / 430).clamp(0.82, 1.22);
            final horizontalPadding = _scaled(width, 0.06, 18, 34);
            final logoSize = _scaled(width, 0.43, 132, 210);
            final titleSize = _scaled(32, scale, 25, 38);
            final bodySize = _scaled(16, scale, 14, 18);
            final buttonHeight = _scaled(58, scale, 52, 64);
            final buttonTextSize = _scaled(21, scale, 18, 23);
            final guestTextSize = _scaled(19, scale, 16, 21);
            final topGap = _scaled(height, 0.14, 46, 108);
            final afterLogoGap = _scaled(height, 0.03, 16, 30);
            final sectionGap = _scaled(height, 0.028, 12, 24);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: topGap),
                        Center(child: _BrandLogo(size: logoSize)),
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
                        SizedBox(height: sectionGap),
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: bodySize,
                              height: 1.5,
                              letterSpacing: 0.15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: _scaled(height, 0.04, 20, 40)),
                      ],
                    ),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              slideRightRoute<void>(
                                const IniciarSessionScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Iniciar sesion',
                            style: TextStyle(
                              fontSize: buttonTextSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              slideRightRoute<void>(const CrearCuentaScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2.2,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Crear una cuenta',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: _scaled(22, scale, 18, 24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: _scaled(sectionGap, 1, 10, 16)),
                      Text(
                        'Echar un vistazo como invitado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: guestTextSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // isGuestMode: sin login (invitado). Con backend, derivar de token/sesion.
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all((size * 0.04).clamp(6, 10).toDouble()),
      decoration: BoxDecoration(color: Colors.white),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset('assets/images/duralon_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
