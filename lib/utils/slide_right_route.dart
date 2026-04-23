import 'package:flutter/cupertino.dart' show CupertinoRouteTransitionMixin;
import 'package:flutter/material.dart';

/// Entrada con transición deslizante (estilo iOS) y **swipe** desde el borde
/// izquierdo hacia la derecha para volver, usando la misma mecánica que
/// [CupertinoPageRoute] (animación de la ruta vinculada al gesto).
Route<T> slideRightRoute<T>(Widget page) {
  return _SlideRightGestureRoute<T>(child: page);
}

class _SlideRightGestureRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  _SlideRightGestureRoute({required this.child, super.settings, super.requestFocus});

  final Widget child;

  @override
  Widget buildContent(BuildContext context) => child;

  @override
  String? get title => null;

  @override
  final bool maintainState = true;

  @override
  String get debugLabel => '${super.debugLabel}(slideRight)';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 420);
}
