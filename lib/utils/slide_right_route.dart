import 'package:flutter/material.dart';

Route<T> slideRightRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Forward push: entra claramente desde la derecha.
      const begin = Offset(1, 0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      final slideTween = Tween<Offset>(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      final fadeTween = Tween<double>(
        begin: 0.85,
        end: 1,
      ).chain(CurveTween(curve: curve));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}
