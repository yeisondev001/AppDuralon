import 'package:app_duralon/config/app_locale.dart';
import 'package:flutter/material.dart';

const _kLangs = [
  ('es', '🇪🇸', 'Español'),
  ('en', '🇺🇸', 'English'),
  ('fr', '🇫🇷', 'Français'),
];

/// Botón compacto que muestra la bandera del idioma activo.
/// Al presionarlo abre un menú con las 3 opciones: 🇪🇸 🇺🇸 🇫🇷.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLang = LocaleScope.lang(context);
    final currentFlag = _kLangs
        .firstWhere((l) => l.$1 == currentLang, orElse: () => _kLangs.first)
        .$2;

    return PopupMenuButton<String>(
      tooltip: '',
      onSelected: AppLocale.instance.setLang,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _kLangs
          .map(
            (l) => PopupMenuItem<String>(
              value: l.$1,
              child: Row(
                children: [
                  Text(l.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    l.$3,
                    style: TextStyle(
                      fontWeight: l.$1 == currentLang
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (l.$1 == currentLang) ...[
                    const Spacer(),
                    const Icon(Icons.check_rounded, size: 18),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(currentFlag, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
