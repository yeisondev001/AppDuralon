import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/pages/iniciar_session_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:app_duralon/utils/show_terminos_bottom_sheet.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class CrearCuentaScreen extends StatefulWidget {
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _rncController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _contactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmarController = TextEditingController();
  final _authService = AuthService();

  String _tipoContribuyente = 'persona_fisica';
  bool _creandoCuenta = false;

  bool _ocultarContrasena = true;
  bool _ocultarConfirmar = true;
  late final TapGestureRecognizer _tapTerminos;

  static double _s(double v, double f, double min, double max) {
    return (v * f).clamp(min, max).toDouble();
  }

  /// Botón rojo sólido solo con los tres campos con texto (actualización en tiempo real).
  bool get _camposLlenos =>
      _emailController.text.trim().isNotEmpty &&
      _rncController.text.trim().isNotEmpty &&
      _razonSocialController.text.trim().isNotEmpty &&
      _contactoController.text.trim().isNotEmpty &&
      _telefonoController.text.trim().isNotEmpty &&
      _direccionController.text.trim().isNotEmpty &&
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
        color: AppColors.secondaryText.withValues(alpha: 0.8),
      ),
      tooltip: 'Borrar',
      onPressed: onPressed,
    );
  }

  @override
  void initState() {
    super.initState();
    _tapTerminos = TapGestureRecognizer()..onTap = _mostrarTerminosYCondiciones;
    _emailController.addListener(_onTextoCambiado);
    _rncController.addListener(_onTextoCambiado);
    _razonSocialController.addListener(_onTextoCambiado);
    _contactoController.addListener(_onTextoCambiado);
    _telefonoController.addListener(_onTextoCambiado);
    _direccionController.addListener(_onTextoCambiado);
    _contrasenaController.addListener(_onTextoCambiado);
    _confirmarController.addListener(_onTextoCambiado);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextoCambiado);
    _rncController.removeListener(_onTextoCambiado);
    _razonSocialController.removeListener(_onTextoCambiado);
    _contactoController.removeListener(_onTextoCambiado);
    _telefonoController.removeListener(_onTextoCambiado);
    _direccionController.removeListener(_onTextoCambiado);
    _contrasenaController.removeListener(_onTextoCambiado);
    _confirmarController.removeListener(_onTextoCambiado);
    _tapTerminos.dispose();
    _emailController.dispose();
    _rncController.dispose();
    _razonSocialController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
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

  void _mostrarTerminosYCondiciones() {
    showTerminosYCondicionesBottomSheet(context);
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    if (!_camposLlenos || _creandoCuenta) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_contrasenaController.text != _confirmarController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Las contraseñas no coinciden'),
              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.9),
            ),
          );
        }
      }
      return;
    }

    setState(() => _creandoCuenta = true);
    try {
      await _authService.registerWholesaleCustomer(
        email: _emailController.text.trim(),
        password: _contrasenaController.text,
        rnc: _rncController.text.trim(),
        taxpayerType: _tipoContribuyente,
        legalName: _razonSocialController.text.trim(),
        contactName: _contactoController.text.trim(),
        phone: _telefonoController.text.trim(),
        fiscalAddress: _direccionController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente')),
      );
      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapRegistroError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _creandoCuenta = false);
      }
    }
  }

  String _mapRegistroError(String message) {
    if (message.contains('email-already-in-use')) {
      return 'Este correo ya esta registrado.';
    }
    if (message.contains('DuplicateRncException')) {
      return 'Este RNC ya esta registrado.';
    }
    if (message.contains('InvalidRncException')) {
      return 'El RNC no es valido.';
    }
    if (message.contains('weak-password')) {
      return 'La contrasena es muy debil.';
    }
    return 'No se pudo crear la cuenta. Intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final width = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale = (width / 430).clamp(0.82, 1.2);
    final pad = _s(width, 0.08, 20, 36);
    final logoGrande = _s(width, 0.38, 120, 190);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: Icon(
                        Icons.arrow_back,
                        size: _s(26, scale, 22, 28),
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/images/duralon_logo.png',
                            width: logoGrande,
                            height: logoGrande,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: _s(height, 0.03, 14, 22)),
                        Text(
                          'Crear una cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: _s(height, 0.02, 10, 16)),
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
                                  color: AppColors.secondaryText,
                                  fontSize: _s(17, scale, 15, 18),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: _navegarAIniciarSesion,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryRed,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Acceder',
                                  style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontSize: _s(17, scale, 15, 18),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _s(height, 0.02, 10, 16)),
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
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
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
                                controller: _rncController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
                                decoration: _baseDecoration('RNC', inputSize),
                                validator: (v) {
                                  final rnc = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                  if (rnc.isEmpty) return 'Ingresa el RNC';
                                  if (rnc.length != 9) return 'El RNC debe tener 9 digitos';
                                  if (!AuthService.isValidDominicanRnc(rnc)) {
                                    return 'RNC invalido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              DropdownButtonFormField<String>(
                                initialValue: _tipoContribuyente,
                                decoration: _baseDecoration('Tipo de empresa', inputSize),
                                dropdownColor: Colors.white,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize * 0.7),
                                items: const [
                                  DropdownMenuItem(value: 'persona_fisica', child: Text('Persona fisica')),
                                  DropdownMenuItem(value: 'sociedad', child: Text('Sociedad')),
                                  DropdownMenuItem(value: 'zona_franca', child: Text('Zona franca')),
                                  DropdownMenuItem(value: 'institucion_gubernamental', child: Text('Institucion gubernamental')),
                                  DropdownMenuItem(value: 'ong_asfl', child: Text('ONG/ASFL')),
                                  DropdownMenuItem(value: 'otro', child: Text('Otro')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _tipoContribuyente = value);
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              TextFormField(
                                controller: _razonSocialController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
                                decoration: _baseDecoration('Razon social', inputSize),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) return 'Ingresa la razon social';
                                  return null;
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              TextFormField(
                                controller: _contactoController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
                                decoration: _baseDecoration('Nombre del contacto', inputSize),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) return 'Ingresa el contacto principal';
                                  return null;
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              TextFormField(
                                controller: _telefonoController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
                                decoration: _baseDecoration('Telefono', inputSize),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) return 'Ingresa un telefono';
                                  return null;
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              TextFormField(
                                controller: _direccionController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                                cursorColor: AppColors.primaryBlue,
                                decoration: _baseDecoration('Direccion fiscal', inputSize),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) return 'Ingresa la direccion fiscal';
                                  return null;
                                },
                              ),
                              SizedBox(height: _s(height, 0.02, 14, 22)),
                              TextFormField(
                        controller: _contrasenaController,
                        obscureText: _ocultarContrasena,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                        cursorColor: AppColors.primaryBlue,
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
                        style: TextStyle(color: AppColors.textDark, fontSize: inputSize),
                        cursorColor: AppColors.primaryBlue,
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
                        SizedBox(height: _s(height, 0.02, 12, 20)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    0,
                    pad,
                    _s(height, 0.02, 12, 20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: _s(14, scale, 12, 15),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Al registrarme, acepto los ',
                            ),
                            TextSpan(
                              text: 'términos y condiciones de uso',
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: _tapTerminos,
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      SizedBox(height: _s(height, 0.02, 10, 14)),
                      SizedBox(
                        width: double.infinity,
                        height: buttonH,
                        child: ElevatedButton(
                          onPressed: (_camposLlenos && !_creandoCuenta)
                              ? _crearCuenta
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primaryRed.withValues(
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
                          child: _creandoCuenta
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: buttonTxt,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
        color: AppColors.primaryBlue.withValues(alpha: 0.7),
        size: 22,
      ),
      tooltip: mostrar ? 'Mostrar contraseña' : 'Ocultar contraseña',
    );
  }

  InputDecoration _baseDecoration(String hint, double size) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.hintColor,
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFB71C1C),
        fontWeight: FontWeight.w500,
        height: 1.3,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputLine, width: 1.2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.8),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryRed, width: 1.2),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primaryRed, width: 1.6),
      ),
    );
  }
}
