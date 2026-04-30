import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

class Step7AddressScreen extends StatefulWidget {
  const Step7AddressScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step7AddressScreen> createState() => _Step7AddressScreenState();
}

class _Step7AddressScreenState extends State<Step7AddressScreen> {
  final _authService = AuthService();
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.data.address ?? '',
  );
  final FocusNode _focus = FocusNode();
  bool _saving = false;

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

  String _taxpayerTypeFromClientType(ClientType? type) {
    switch (type) {
      case ClientType.empresa:
        return 'empresa';
      case ClientType.zonaFranca:
        return 'zona_franca';
      case ClientType.gubernamental:
        return 'gubernamental';
      case ClientType.personaFisica:
      case null:
        return 'persona_fisica';
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    widget.data.address = _ctrl.text.trim();
    setState(() => _saving = true);
    try {
      await _authService.completeGoogleCustomerOnboarding(
        user: user,
        taxpayerType: _taxpayerTypeFromClientType(widget.data.clientType),
        fullName: widget.data.name ?? '',
        identification: widget.data.taxId ?? '',
        city: widget.data.city ?? '',
        country: widget.data.country,
        phone: widget.data.phone ?? '',
        fiscalAddress: widget.data.address ?? '',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );
    } on DuplicateIdentificationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa identificación ya está registrada.')),
      );
    } on InvalidIdentificationException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Identificación inválida.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar el onboarding.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _ctrl.text.trim().length >= 5;
    return OnboardingScaffold(
      step: 7,
      totalSteps: 7,
      title: 'Dirección',
      subtitle: 'Ingresa tu dirección completa.',
      canContinue: isValid && !_saving,
      continueLabel: _saving ? 'Guardando...' : 'Finalizar',
      onContinue: _finish,
      child: RoundedTextField(
        controller: _ctrl,
        focusNode: _focus,
        hint: 'Calle, número, sector',
        icon: Icons.home_outlined,
        iconColor: const Color(0xFFFB8C00),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) {
          if (isValid && !_saving) _finish();
        },
      ),
    );
  }
}
