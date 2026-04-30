import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/step_5_phone.dart';
import 'package:app_duralon/services/auth_service.dart';

class Step4TaxIdScreen extends StatefulWidget {
  const Step4TaxIdScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step4TaxIdScreen> createState() => _Step4TaxIdScreenState();
}

class _Step4TaxIdScreenState extends State<Step4TaxIdScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.taxId ?? '',
  );
  final FocusNode _focus = FocusNode();

  bool get _isDominican => widget.data.isDominicanRepublic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Luhn dominicano para cédula (duplicado aquí para evitar acceso a método privado de AuthService)
  bool _checkCedula(String d) {
    if (d.length != 11) return false;
    final digits = d.split('').map(int.parse).toList();
    const weights = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final p = digits[i] * weights[i];
      sum += p > 9 ? p - 9 : p;
    }
    return (10 - (sum % 10)) % 10 == digits[10];
  }

  bool _checkRnc(String d) => AuthService.isValidDominicanRnc(d);

  bool get _isValid {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return false;
    if (!_isDominican) return raw.length >= 3;
    final d = raw.replaceAll(RegExp(r'\D'), '');
    // Solo valida longitud correcta; el checksum es indicador visual, no bloqueante.
    if (widget.data.isCompany) return d.length == 9;
    return d.length == 11;
  }

  // null = aún no hay suficientes dígitos (no mostrar nada)
  // true = válido   false = longitud completa pero checksum falla
  bool? get _checkResult {
    if (!_isDominican) return null;
    final d = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    final targetLen = widget.data.isCompany ? 9 : 11;
    if (d.length < targetLen) return null;
    return widget.data.isCompany ? _checkRnc(d) : _checkCedula(d);
  }

  String? get _detected {
    final r = _checkResult;
    if (r == null) return null;
    if (widget.data.isCompany) return r ? 'RNC válido' : 'RNC inválido — verifica los dígitos';
    return r ? 'Cédula válida' : 'Cédula inválida — verifica los dígitos';
  }

  void _next() {
    widget.data.taxId = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step5PhoneScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.data.isCompany;
    final valid = _checkResult;
    final accentColor = !_isDominican
        ? const Color(0xFF3949AB)
        : valid == false
        ? const Color(0xFFE53935)
        : isCompany
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);
    final title = !_isDominican
        ? 'Identificación fiscal / Tax ID'
        : isCompany
        ? 'RNC'
        : 'Cédula';
    final subtitle = !_isDominican
        ? 'Ingresa tu identificación fiscal.\nCampo requerido.'
        : isCompany
        ? 'Escribe el RNC fiscal de tu empresa.'
        : 'Ingresa tu cédula.\n11 dígitos.';

    return OnboardingScaffold(
      step: 4,
      totalSteps: 7,
      title: title,
      subtitle: subtitle,
      canContinue: _isValid,
      onContinue: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: _isDominican
                ? TextInputType.number
                : TextInputType.text,
            inputFormatters: _isDominican
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(isCompany ? 9 : 11),
                    _TaxIdFormatter(isCompany: isCompany),
                  ]
                : null,
            onSubmitted: (_) {
              if (_isValid) _next();
            },
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: !_isDominican
                  ? 'Tax ID / VAT / EIN'
                  : isCompany
                  ? '000-00000-0'
                  : '000-0000000-0',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
              prefixIcon: Icon(
                !_isDominican
                    ? Icons.badge_outlined
                    : isCompany
                    ? Icons.business_outlined
                    : Icons.badge_outlined,
                color: accentColor,
                size: 22,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _detected == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_detected),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _checkResult == false ? Icons.cancel : Icons.check_circle,
                          color: accentColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _detected!,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaxIdFormatter extends TextInputFormatter {
  _TaxIdFormatter({required this.isCompany});
  final bool isCompany;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    final d = newV.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();

    if (isCompany) {
      for (var i = 0; i < d.length; i++) {
        if (i == 3 || i == 8) buf.write('-');
        buf.write(d[i]);
      }
    } else {
      for (var i = 0; i < d.length; i++) {
        if (i == 3 || i == 10) buf.write('-');
        buf.write(d[i]);
      }
    }

    final f = buf.toString();
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}
