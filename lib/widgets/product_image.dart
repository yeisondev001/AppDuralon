import 'package:flutter/material.dart';

/// Muestra la imagen de un producto: usa [Image.network] si [src] empieza con
/// "http", o [Image.asset] en caso contrario. Incluye indicador de carga y
/// fallback al logo cuando la red falla.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    debugPrint('[ProductImage] src=$src');
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, e, stack) {
          debugPrint('[ProductImage] ERROR cargando $src → $e');
          return Image.asset(
            'assets/images/duralon_logo.png',
            fit: fit,
            width: width,
            height: height,
          );
        },
      );
    }
    debugPrint('[ProductImage] usando asset local: $src');
    return Image.asset(
      src,
      fit: fit,
      width: width,
      height: height,
    );
  }
}
