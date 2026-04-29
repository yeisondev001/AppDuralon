import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/step_4_phone.dart';

class Step3TaxIdScreen extends StatefulWidget {
  const Step3TaxIdScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step3TaxIdScreen> createState() => _Step3TaxIdScreenState();
}

class _Step3TaxIdScreenState extends State<Step3TaxIdScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.taxId ?? '',
  );
  final FocusNode _focus = FocusNode();

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

  bool get _isValid {
    final d = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (widget.data.isCompany) return d.length == 9;
    return d.length == 11;
  }

  String? get _detected {
    final d = _ctrl.text.replaceAll(RegExp(r'\D'), '');
    if (widget.data.isCompany && d.length == 9) return 'RNC válido';
    if (!widget.data.isCompany && d.length == 11) return 'Cédula válida';
    return null;
  }

  void _next() {
    widget.data.taxId = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step4PhoneScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.data.isCompany;

    return OnboardingScaffold(
      step: 3,
      totalSteps: 7,
      title: isCompany ? 'RNC de la empresa' : 'Tu cédula',
      subtitle: isCompany
          ? 'Ingresa el RNC registrado.\n9 dígitos.'
          : 'Ingresa tu cédula de identidad.\n11 dígitos.',
      canContinue: _isValid,
      onContinue: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(isCompany ? 9 : 11),
              _TaxIdFormatter(isCompany: isCompany),
            ],
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
              hintText: isCompany ? '000-00000-0' : '000-0000000-0',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
              prefixIcon: Icon(
                isCompany ? Icons.business_outlined : Icons.badge_outlined,
                color: AppColors.accentBlue,
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
                borderSide: const BorderSide(
                  color: AppColors.accentBlue,
                  width: 1.5,
                ),
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
                      color: AppColors.accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.accentBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _detected!,
                          style: const TextStyle(
                            color: AppColors.accentBlue,
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
