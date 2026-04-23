import 'package:flutter/material.dart';

const Color _primaryBlue = Color(0xFF0059B7);
const Color _textDark = Color(0xFF1C1C1C);

void showTerminosYCondicionesBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final altura = MediaQuery.sizeOf(ctx).height * 0.58;
      return SafeArea(
        child: SizedBox(
          height: altura,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDFE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Términos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Términos y condiciones de uso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5F6B7A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Vista de demostración: aquí irá el texto legal completo '
                    'cuando lo tengan redactado o enlazado con el sitio web.\n\n'
                    'Al usar Plásticos Duralon aceptas las políticas de compra, '
                    'entrega, privacidad y uso de datos según la legislación '
                    'aplicable. Este bloque es solo un ejemplo de contenido.\n\n'
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Puedes desplazarte y cerrar con el botón inferior o '
                    'arrastrando hacia abajo.',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
