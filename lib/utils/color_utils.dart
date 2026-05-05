import 'package:flutter/material.dart';

bool isTransparentColor(String name) =>
    name == 'Clear' || name == 'Transparente';

/// Pinta un patrón de tablero de ajedrez (gris/blanco) para indicar transparencia.
class ColorCheckerPainter extends CustomPainter {
  const ColorCheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final half = size.width / 2;
    final paint = Paint();
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, half, half), paint);
    canvas.drawRect(Rect.fromLTWH(half, half, half, half), paint);
    paint.color = const Color(0xFFCCCCCC);
    canvas.drawRect(Rect.fromLTWH(half, 0, half, half), paint);
    canvas.drawRect(Rect.fromLTWH(0, half, half, half), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
