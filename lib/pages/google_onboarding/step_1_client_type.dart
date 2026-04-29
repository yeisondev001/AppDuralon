import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/step_2_name.dart';

class Step1ClientTypeScreen extends StatefulWidget {
  const Step1ClientTypeScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step1ClientTypeScreen> createState() => _Step1ClientTypeScreenState();
}

class _Step1ClientTypeScreenState extends State<Step1ClientTypeScreen> {
  ClientType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.clientType;
  }

  void _next() {
    widget.data.clientType = _selected;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step2NameScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 1,
      totalSteps: 7,
      title: '¿Qué tipo de cliente eres?',
      subtitle: 'Esto nos ayuda a personalizar\nlos siguientes pasos.',
      canContinue: _selected != null,
      onContinue: _next,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: ClientType.values.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final t = ClientType.values[i];
          return ClientTypeCard(
            type: t,
            selected: _selected == t,
            onTap: () => setState(() => _selected = t),
          );
        },
      ),
    );
  }
}

class ClientTypeCard extends StatelessWidget {
  const ClientTypeCard({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ClientType type;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (type) {
      case ClientType.empresa:
        return Icons.business_center_outlined;
      case ClientType.zonaFranca:
        return Icons.local_shipping_outlined;
      case ClientType.gubernamental:
        return Icons.account_balance_outlined;
      case ClientType.personaFisica:
        return Icons.person_outline;
    }
  }

  String get _description {
    switch (type) {
      case ClientType.empresa:
        return 'Negocios privados con RNC activo';
      case ClientType.zonaFranca:
        return 'Empresas operando en zonas francas';
      case ClientType.gubernamental:
        return 'Instituciones del estado y municipales';
      case ClientType.personaFisica:
        return 'Cuenta individual con cédula';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.accentBlue : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accentBlue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? null
                        : Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    _icon,
                    color: selected ? Colors.white : AppColors.accentBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.accentBlue : AppColors.border,
                      width: 2,
                    ),
                    color: selected ? AppColors.accentBlue : Colors.white,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
