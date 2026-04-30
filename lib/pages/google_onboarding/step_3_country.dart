import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/step_4_tax_id.dart';

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

class Step3CountryScreen extends StatefulWidget {
  const Step3CountryScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step3CountryScreen> createState() => _Step3CountryScreenState();
}

class _Step3CountryScreenState extends State<Step3CountryScreen> {
  String _query = '';
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.country;
  }

  void _next() {
    widget.data.country = _selected;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step4TaxIdScreen(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _countries
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return OnboardingScaffold(
      step: 3,
      totalSteps: 7,
      title: 'País',
      subtitle: 'Selecciona tu país de residencia.',
      canContinue: _selected.isNotEmpty,
      onContinue: _next,
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
              itemBuilder: (context, i) {
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
