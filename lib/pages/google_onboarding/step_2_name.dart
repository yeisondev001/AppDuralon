import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_3_tax_id.dart';

class Step2NameScreen extends StatefulWidget {
  const Step2NameScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step2NameScreen> createState() => _Step2NameScreenState();
}

class _Step2NameScreenState extends State<Step2NameScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.name ?? '',
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

  void _next() {
    widget.data.name = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step3TaxIdScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = widget.data.isCompany;
    final isValid = _ctrl.text.trim().length >= 2;

    return OnboardingScaffold(
      step: 2,
      totalSteps: 7,
      title: isCompany ? 'Nombre de la empresa' : '¿Cuál es tu nombre?',
      subtitle: isCompany
          ? 'La razón social como aparece\nen tu RNC.'
          : 'Así aparecerás en facturas y\ncomprobantes fiscales.',
      canContinue: isValid,
      onContinue: _next,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: isCompany ? 'Razón social' : 'Nombre y apellido',
        icon: isCompany ? Icons.apartment : Icons.person_outline,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) {
          if (isValid) _next();
        },
      ),
    );
  }
}
