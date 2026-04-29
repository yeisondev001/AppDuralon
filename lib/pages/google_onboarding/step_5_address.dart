import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_6_city.dart';

class Step5AddressScreen extends StatefulWidget {
  const Step5AddressScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step5AddressScreen> createState() => _Step5AddressScreenState();
}

class _Step5AddressScreenState extends State<Step5AddressScreen> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.address ?? '',
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
    widget.data.address = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step6CityScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _ctrl.text.trim().length >= 5;
    return OnboardingScaffold(
      step: 5,
      totalSteps: 7,
      title: 'Dirección',
      subtitle: 'Calle, número y sector\npara entregas.',
      canContinue: isValid,
      onContinue: _next,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: 'Calle, número, sector',
        icon: Icons.home_outlined,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) {
          if (isValid) _next();
        },
      ),
    );
  }
}
