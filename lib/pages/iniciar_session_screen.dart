import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_duralon/pages/crear_cuenta_screen.dart';
import 'package:app_duralon/pages/recuperar_cuenta_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class IniciarSessionScreen extends StatefulWidget {
  const IniciarSessionScreen({super.key});

  @override
  State<IniciarSessionScreen> createState() => _IniciarSessionScreenState();
}

class _IniciarSessionScreenState extends State<IniciarSessionScreen> {
  // Misma paleta que login_screen
  static const Color primaryBlue = Color(0xFF0059B7);
  static const Color primaryRed = Color(0xFFFF0018);
  static const Color inputLine = Color(0xFFB6BAC2);
  static const Color hintColor = Color(0xFFB5B8BE);
  static const Color secondaryText = Color(0xFF3F4E66);

  static const Color _textDark = Color(0xFF1C1C1C);

  /// Fondo rojo muy claro para el aviso de error
  static const Color _errorBg = Color(0xFFFFE8E8);
  static const Color _errorText = Color(0xFFB71C1C);

  /// Mensaje cuando correo o contraseña no coinciden (frontend; luego vendrá del API)
  static const String _msgCredencialesIncorrectas =
      'El usuario o la contraseña introducidos no son correctos.';

  /// Color fijo del icono ojito (no usar azul de marca en este sitio)
  static const Color _iconoOjito = Color.fromARGB(255, 161, 161, 160);

  /// Cuánto se muestra el aviso de error antes de ocultarse solo
  static const Duration _duracionAvisoError = Duration(seconds: 4);

  bool _ocultarContrasena = true;
  String? _mensajeErrorLogin;
  Timer? _ocultarErrorTimer;

  late final TextEditingController _correoController;
  late final TextEditingController _contrasenaController;

  static double _scaled(double v, double f, double min, double max) {
    return (v * f).clamp(min, max).toDouble();
  }

  bool get _puedeIniciarSesion =>
      _correoController.text.trim().isNotEmpty &&
      _contrasenaController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _correoController = TextEditingController();
    _contrasenaController = TextEditingController();
    void alCambiarTexto() => setState(() {
      _ocultarErrorTimer?.cancel();
      _mensajeErrorLogin = null;
    });
    _correoController.addListener(alCambiarTexto);
    _contrasenaController.addListener(alCambiarTexto);
  }

  /// Simulación sin backend: solo este correo + contraseña se aceptan (para probar éxito).
  /// Cualquier otra combinación muestra el aviso en rojo.
  void _intentarIniciarSesion() {
    FocusScope.of(context).unfocus();
    final email = _correoController.text.trim();
    final pass = _contrasenaController.text;

    // TODO(app): reemplazar por login real con API
    const demoEmail = 'demo@plasticosduralon.com';
    const demoPass = 'duralon123';

    if (email == demoEmail && pass == demoPass) {
      _ocultarErrorTimer?.cancel();
      setState(() => _mensajeErrorLogin = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión iniciada (modo demo, sin servidor)'),
        ),
      );
      return;
    }

    setState(() {
      _mensajeErrorLogin = _msgCredencialesIncorrectas;
    });
    _programarOcultarAvisoError();
  }

  void _programarOcultarAvisoError() {
    _ocultarErrorTimer?.cancel();
    _ocultarErrorTimer = Timer(_duracionAvisoError, () {
      if (!mounted) return;
      setState(() => _mensajeErrorLogin = null);
    });
  }

  void _vaciarCorreo() => _correoController.clear();

  /// X al final del correo (la contraseña solo lleva ojito, sin X).
  Widget _iconoBorrarCorreo() {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.only(right: 2),
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      icon: Icon(
        Icons.close,
        size: 18,
        color: secondaryText.withValues(alpha: 0.8),
      ),
      tooltip: 'Borrar',
      onPressed: _vaciarCorreo,
    );
  }

  @override
  void dispose() {
    _ocultarErrorTimer?.cancel();
    _correoController.dispose();
    _contrasenaController.dispose();
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
    final inputFontSize = _scaled(34, scale, 18, 22);
    final buttonHeight = _scaled(58, scale, 52, 64);
    final buttonTextSize = _scaled(21, scale, 18, 23);

    // Sin Column+Expanded+ListView: ListView bajo SafeArea con restricción finita
    // del Scaffold (evita error del viewport / SingleChildScrollView interno).
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      resizeToAvoidBottomInset: true,
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Material(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              children: [
                SizedBox(height: _scaled(height, 0.02, 8, 18)),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back,
                    size: _scaled(28, scale, 22, 30),
                    color: primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(height: _scaled(height, 0.06, 24, 56)),
                // Mismo fondo blanco que login_screen, sin marco ni sombra
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
                SizedBox(height: _scaled(height, 0.05, 24, 48)),
                TextField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: TextStyle(color: _textDark, fontSize: inputFontSize),
                  cursorColor: primaryBlue,
                  decoration: InputDecoration(
                    hintText: 'Gmail o correo electrónico',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: inputLine, width: 1),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryBlue, width: 1.6),
                    ),
                    suffixIcon: _correoController.text.isNotEmpty
                        ? _iconoBorrarCorreo()
                        : null,
                  ),
                ),
                SizedBox(height: _scaled(height, 0.03, 20, 30)),
                TextField(
                  controller: _contrasenaController,
                  style: TextStyle(color: _textDark, fontSize: inputFontSize),
                  cursorColor: primaryBlue,
                  obscureText: _ocultarContrasena,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (_puedeIniciarSesion) {
                      _intentarIniciarSesion();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: inputFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _ocultarContrasena = !_ocultarContrasena;
                        });
                      },
                      icon: Icon(
                        _ocultarContrasena
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _iconoOjito,
                        size: 22,
                      ),
                      tooltip: _ocultarContrasena
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: inputLine, width: 1),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryBlue, width: 1.6),
                    ),
                  ),
                ),
                SizedBox(height: _scaled(height, 0.022, 14, 22)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        slideRightRoute<void>(const RecuperarCuentaScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryRed,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Recuperar cuenta',
                      style: TextStyle(
                        fontSize: _scaled(17, scale, 15, 18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _scaled(height, 0.06, 24, 72)),
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
                        color: primaryRed.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: primaryRed.withValues(alpha: 0.85),
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
                  SizedBox(height: _scaled(height, 0.02, 10, 16)),
                ] else
                  SizedBox(height: _scaled(height, 0.04, 12, 28)),
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: _puedeIniciarSesion
                        ? _intentarIniciarSesion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryRed.withValues(
                        alpha: 0.35,
                      ),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _scaled(height, 0.025, 14, 24)),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        '¿Aún no tienes una cuenta? ',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: _scaled(18, scale, 16, 20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            slideRightRoute<void>(const CrearCuentaScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Crear una',
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: _scaled(18, scale, 16, 20),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _scaled(height, 0.04, 20, 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
