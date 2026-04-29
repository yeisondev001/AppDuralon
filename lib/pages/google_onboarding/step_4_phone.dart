import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_5_address.dart';

class Step4PhoneScreen extends StatefulWidget {
  const Step4PhoneScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step4PhoneScreen> createState() => _Step4PhoneScreenState();
}

class _Step4PhoneScreenState extends State<Step4PhoneScreen> {
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

  bool get _isValid => _ctrl.text.replaceAll(RegExp(r'\D'), '').length == 10;

  void _next() {
    widget.data.phone = _ctrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step5AddressScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 4,
      totalSteps: 7,
      title: 'Número de teléfono',
      subtitle: 'Para confirmaciones de pedidos\ny atención al cliente.',
      canContinue: _isValid,
      onContinue: _next,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: '(809) 000-0000',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          _PhoneFormatter(),
        ],
        onSubmitted: (_) {
          if (_isValid) _next();
        },
      ),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    final d = newV.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 3) buf.write(') ');
      if (i == 6) buf.write('-');
      buf.write(d[i]);
    }
    final f = buf.toString();
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}
