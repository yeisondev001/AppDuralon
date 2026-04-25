import 'dart:ui' show ImageFilter;

import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/slide_right_route.dart';
import 'package:flutter/material.dart';

const Duration _kGuestDialogTransition = Duration(milliseconds: 400);

/// Curva de entrada: suave; al cerrar [Curves.easeInCubic] hace el dismiss menos brusco.
CurvedAnimation _guestDialogCurved(Animation<double> parent) {
  return CurvedAnimation(
    parent: parent,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
}

/// Invitado intenta usar el carrito: pide acceder a Duralon o seguir explorando.
/// Fondo borroso estilo vitral (misma idea que el visor de foto en [ProductoScreen]).
/// Entrada con fade + slide suave (evita aparicion brusca).
Future<void> showDuralonGuestCartDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.transparent,
    transitionDuration: _kGuestDialogTransition,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final size = MediaQuery.sizeOf(context);
      return SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Capa inferior: cierre al tocar fuera de la tarjeta
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Contenido nítido encima
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.95),
                    clipBehavior: Clip.antiAlias,
                    elevation: 8,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ACCEDE A DURALON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Para poder hacer tus compras, crea tu cuenta o inicia sesion',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: AppColors.secondaryText.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).push<void>(
                                  slideRightRoute<void>(const LoginScreen()),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'ACCEDER',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'AHORA NO, CONTINUAR',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = _guestDialogCurved(animation);
      // Deslizamiento leve desde abajo + leve acercamiento; fondo acompana el fade.
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.14),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
