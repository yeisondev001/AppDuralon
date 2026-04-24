import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_duralon/styles/app_style.dart';

class RecuperarCuentaScreen extends StatefulWidget {
  const RecuperarCuentaScreen({super.key});

  @override
  State<RecuperarCuentaScreen> createState() => _RecuperarCuentaScreenState();
}

class _RecuperarCuentaScreenState extends State<RecuperarCuentaScreen> {
  static const Color _errorBg = Color(0xFFFFE8E8);
  static const Color _errorText = Color(0xFFB71C1C);
  static const Duration _duracionAviso = Duration(seconds: 4);
  static const String _msgCorreoNoValidoDemo =
      'Ese Gmail o correo no es correcto o no está registrado. Aún no hay conexión con el servidor: cuando conecte el backend, aquí comprobará el correo de verdad.';

  String? _mensajeAviso;
  Timer? _ocultarAvisoTimer;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  static double _s(double v, double f, double min, double max) {
    return (v * f).clamp(min, max).toDouble();
  }

  bool get _emailNoVacio => _emailController.text.trim().isNotEmpty;

  void _onTextoCambiado() {
    _ocultarAvisoTimer?.cancel();
    setState(() {
      _mensajeAviso = null;
    });
  }

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
    _emailController.addListener(_onTextoCambiado);
  }

  @override
  void dispose() {
    _ocultarAvisoTimer?.cancel();
    _emailController.removeListener(_onTextoCambiado);
    _emailController.dispose();
    super.dispose();
  }

  void _programarOcultarAviso() {
    _ocultarAvisoTimer?.cancel();
    _ocultarAvisoTimer = Timer(_duracionAviso, () {
      if (!mounted) return;
      setState(() => _mensajeAviso = null);
    });
  }

  void _continuar() {
    FocusScope.of(context).unfocus();
    if (!_emailNoVacio) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!mounted) return;
    // TODO(app): comprobar email en API
    setState(() => _mensajeAviso = _msgCorreoNoValidoDemo);
    _programarOcultarAviso();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final width = w.isFinite && w > 0 ? w : 400.0;
    final height = h.isFinite && h > 0 ? h : 700.0;
    final scale = (width / 430).clamp(0.82, 1.2);
    final pad = _s(width, 0.08, 20, 36);
    final logoSize = _s(width, 0.32, 120, 170);
    final inputSize = _s(34, scale, 16, 20);
    final titleSize = _s(26, scale, 20, 30);
    final buttonH = _s(58, scale, 52, 64);
    final buttonTxt = _s(20, scale, 17, 22);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: ColoredBox(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Material(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      SizedBox(height: _s(height, 0.01, 6, 12)),
                      Align(
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
                      SizedBox(height: _s(height, 0.04, 16, 40)),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/duralon_logo.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: _s(height, 0.04, 20, 36)),
                      Center(
                        child: Text(
                          'Recuperar cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: _s(height, 0.05, 24, 44)),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) {
                            if (_emailNoVacio) _continuar();
                          },
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: inputSize,
                          ),
                          cursorColor: AppColors.primaryBlue,
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico',
                            hintStyle: TextStyle(
                              color: AppColors.hintColor,
                              fontSize: inputSize,
                              fontWeight: FontWeight.w500,
                            ),
                            errorStyle: const TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.inputLine,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryBlue,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryRed,
                                width: 1.2,
                              ),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primaryRed,
                                width: 1.6,
                              ),
                            ),
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
                      ),
                      SizedBox(height: _s(height, 0.06, 24, 72)),
                      if (_mensajeAviso != null) ...[
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
                              color: AppColors.primaryRed.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.primaryRed.withValues(alpha: 0.85),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _mensajeAviso!,
                                  style: TextStyle(
                                    color: _errorText,
                                    fontSize: _s(15, scale, 13, 16),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: _s(height, 0.02, 10, 16)),
                      ] else
                        SizedBox(height: _s(height, 0.04, 12, 28)),
                      SizedBox(height: _s(height, 0.12, 40, 100)),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Material(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: buttonH,
                    child: ElevatedButton(
                      onPressed: _emailNoVacio ? _continuar : null,
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
                      child: Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: buttonTxt,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
