import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

const _countries = <_Country>[
  _Country('República Dominicana', '🇩🇴'),
  _Country('Puerto Rico', '🇵🇷'),
  _Country('Costa Rica', '🇨🇷'),
  _Country('Canadá', '🇨🇦'),
  _Country('Estados Unidos', '🇺🇸'),
  _Country('Panamá', '🇵🇦'),
  _Country('Trinidad y Tobago', '🇹🇹'),
  _Country('Haití', '🇭🇹'),
  _Country('Aruba', '🇦🇼'),
  _Country('Jamaica', '🇯🇲'),
  _Country('Barbados', '🇧🇧'),
];

class _Country {
  final String name;
  final String flag;
  const _Country(this.name, this.flag);
}

class Step7CountryScreen extends StatefulWidget {
  const Step7CountryScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step7CountryScreen> createState() => _Step7CountryScreenState();
}

class _Step7CountryScreenState extends State<Step7CountryScreen> {
  final _authService = AuthService();
  String _query = '';
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.country ?? 'República Dominicana';
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

    widget.data.country = _selected;
    setState(() => _saving = true);
    try {
      await _authService.completeGoogleCustomerOnboarding(
        user: user,
        taxpayerType: _taxpayerTypeFromClientType(widget.data.clientType),
        fullName: widget.data.name ?? '',
        identification: widget.data.taxId ?? '',
        city: widget.data.city ?? '',
        country: widget.data.country ?? '',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.data.isCompany
                ? 'Debes ingresar un RNC válido.'
                : 'Debes ingresar una cédula válida.',
          ),
        ),
      );
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
    final filtered = _countries
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return OnboardingScaffold(
      step: 7,
      totalSteps: 7,
      title: 'País',
      subtitle: 'Selecciona tu país de residencia.',
      canContinue: _selected != null && !_saving,
      continueLabel: _saving ? 'Guardando...' : 'Finalizar',
      onContinue: _finish,
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Buscar país…',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.accentBlue,
                size: 22,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = filtered[i];
                final selected = _selected == c.name;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = c.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.accentBlue
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(c.flag, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.accentBlue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
