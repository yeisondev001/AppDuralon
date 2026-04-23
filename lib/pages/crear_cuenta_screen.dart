import 'package:flutter/material.dart';
import 'package:app_duralon/pages/iniciar_session_screen.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class CrearCuentaScreen extends StatefulWidget {
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  static const Color primaryBlue = Color(0xFF0059B7);
  static const Color primaryRed = Color(0xFFFF0018);
  static const Color inputLine = Color(0xFFB6BAC2);
  static const Color hintColor = Color(0xFFB5B8BE);
  static const Color secondaryText = Color(0xFF3F4E66);
  static const Color _textDark = Color(0xFF1C1C1C);

  static const String _leyenda =
      'Al registrarme, acepto los términos y condiciones de uso.';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;

  static double _s(double v, double f, double min, double max) {
    return (v * f).clamp(min, max).toDouble();
  }

  /// Botón rojo sólido solo con los tres campos con texto (actualización en tiempo real).
  bool get _camposLlenos =>
      _emailController.text.trim().isNotEmpty &&
      _contrasenaController.text.isNotEmpty &&
      _confirmarController.text.isNotEmpty;

  void _onTextoCambiado() => setState(() {});

  void _vaciarCorreo() => _emailController.clear();

  /// X pequeña al final; solo visible si hay texto.
  Widget _iconoBorrar({required VoidCallback onPressed}) {
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
      onPressed: onPressed,
    );
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextoCambiado);
    _contrasenaController.addListener(_onTextoCambiado);
    _confirmarController.addListener(_onTextoCambiado);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextoCambiado);
    _contrasenaController.removeListener(_onTextoCambiado);
    _confirmarController.removeListener(_onTextoCambiado);
    _emailController.dispose();
    _contrasenaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _navegarAIniciarSesion() {
    Navigator.push<void>(
      context,
      slideRightRoute<void>(const IniciarSessionScreen()),
    );
  }

  void _crearCuenta() {
    FocusScope.of(context).unfocus();
    if (!_camposLlenos) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_contrasenaController.text != _confirmarController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Las contraseñas no coinciden'),
              backgroundColor: primaryRed.withValues(alpha: 0.9),
            ),
          );
        }
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada (modo demo; conectar con API después)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final width = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale = (width / 430).clamp(0.82, 1.2);
    final pad = _s(width, 0.08, 20, 36);
    final smallLogo = _s(width, 0.12, 44, 58);
    final inputSize = _s(34, scale, 16, 20);
    final buttonH = _s(58, scale, 52, 64);
    final buttonTxt = _s(21, scale, 18, 23);
    final titleSize = _s(22, scale, 18, 24);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Material(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: pad),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const ClampingScrollPhysics(),
              children: [
                SizedBox(height: _s(height, 0.02, 6, 16)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.arrow_back,
                        size: _s(26, scale, 22, 28),
                        color: primaryBlue,
                      ),
                    ),
                    SizedBox(width: _s(width, 0.01, 4, 8)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/duralon_logo.png',
                        width: smallLogo,
                        height: smallLogo,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: _s(width, 0.03, 10, 14)),
                    Expanded(
                      child: Text(
                        'Crear una cuenta',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _s(height, 0.04, 20, 36)),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta?',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: _s(17, scale, 15, 18),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: _navegarAIniciarSesion,
                        style: TextButton.styleFrom(
                          foregroundColor: primaryRed,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Acceder',
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: _s(17, scale, 15, 18),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _s(height, 0.04, 20, 32)),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: TextStyle(color: _textDark, fontSize: inputSize),
                        cursorColor: primaryBlue,
                        decoration:
                            _baseDecoration(
                              'Correo electrónico',
                              inputSize,
                            ).copyWith(
                              suffixIcon: _emailController.text.isNotEmpty
                                  ? _iconoBorrar(onPressed: _vaciarCorreo)
                                  : null,
                            ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Ingresa tu correo';
                          if (!t.contains('@') || t.length < 5) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _s(height, 0.02, 14, 22)),
                      TextFormField(
                        controller: _contrasenaController,
                        obscureText: _ocultarContrasena,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: TextStyle(color: _textDark, fontSize: inputSize),
                        cursorColor: primaryBlue,
                        decoration: _baseDecoration('Contraseña', inputSize)
                            .copyWith(
                              suffixIcon: _suffixOjoContrasena(
                                mostrar: _ocultarContrasena,
                                onToggle: () => setState(
                                  () =>
                                      _ocultarContrasena = !_ocultarContrasena,
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (v.length < 4) {
                            return 'Mínimo 4 caracteres';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: _s(height, 0.02, 14, 22)),
                      TextFormField(
                        controller: _confirmarController,
                        obscureText: _ocultarConfirmar,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        style: TextStyle(color: _textDark, fontSize: inputSize),
                        cursorColor: primaryBlue,
                        onFieldSubmitted: (_) {
                          if (_camposLlenos) _crearCuenta();
                        },
                        decoration:
                            _baseDecoration(
                              'Confirmar contraseña',
                              inputSize,
                            ).copyWith(
                              suffixIcon: _suffixOjoContrasena(
                                mostrar: _ocultarConfirmar,
                                onToggle: () => setState(
                                  () => _ocultarConfirmar = !_ocultarConfirmar,
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (v != _contrasenaController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _s(height, 0.04, 16, 28)),
                Text(
                  _leyenda,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: _s(14, scale, 12, 15),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _s(height, 0.04, 20, 36)),
                SizedBox(
                  width: double.infinity,
                  height: buttonH,
                  child: ElevatedButton(
                    onPressed: _camposLlenos ? _crearCuenta : null,
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
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: buttonTxt,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _s(height, 0.04, 20, 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suffixOjoContrasena({
    required bool mostrar,
    required VoidCallback onToggle,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      onPressed: onToggle,
      icon: Icon(
        mostrar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: primaryBlue.withValues(alpha: 0.7),
        size: 22,
      ),
      tooltip: mostrar ? 'Mostrar contraseña' : 'Ocultar contraseña',
    );
  }

  InputDecoration _baseDecoration(String hint, double size) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFB71C1C),
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: inputLine, width: 1.2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: primaryBlue, width: 1.8),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF0018), width: 1.2),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF0018), width: 1.6),
      ),
    );
  }
}
