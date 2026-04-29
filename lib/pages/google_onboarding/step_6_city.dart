import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_7_address.dart';

class Step6CityScreen extends StatefulWidget {
  const Step6CityScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step6CityScreen> createState() => _Step6CityScreenState();
}

class _Step6CityScreenState extends State<Step6CityScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.city ?? '',
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
    widget.data.city = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step7AddressScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _ctrl.text.trim().length >= 2;
    return OnboardingScaffold(
      step: 6,
      totalSteps: 7,
      title: 'Ciudad',
      subtitle: '¿En qué ciudad te encuentras?',
      canContinue: isValid,
      onContinue: _next,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: 'Ej: Santo Domingo',
        icon: Icons.location_city_outlined,
        iconColor: const Color(0xFF8E24AA),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) {
          if (isValid) _next();
        },
      ),
    );
  }
}
