import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_6_city.dart';

class Step5PhoneScreen extends StatefulWidget {
  const Step5PhoneScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step5PhoneScreen> createState() => _Step5PhoneScreenState();
}

class _Step5PhoneScreenState extends State<Step5PhoneScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.phone ?? '',
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

  bool get _isValid => _ctrl.text.trim().isNotEmpty;

  void _next() {
    widget.data.phone = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step6CityScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 5,
      totalSteps: 7,
      title: 'Teléfono',
      subtitle: 'Ingresa un número de contacto.',
      canContinue: _isValid,
      onContinue: _next,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: '(809) 000-0000',
        icon: Icons.phone_outlined,
        iconColor: const Color(0xFF43A047),
        keyboardType: TextInputType.phone,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9()+\-\s]')),
          LengthLimitingTextInputFormatter(20),
        ],
        onSubmitted: (_) {
          if (_isValid) _next();
        },
      ),
    );
  }
}
