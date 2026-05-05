import 'package:app_duralon/services/locale_service.dart';
import 'package:flutter/material.dart';

/// Botón compacto que muestra la bandera del idioma activo y despliega un
/// menú para cambiar entre Español 🇪🇸, English 🇺🇸 y Français 🇫🇷.
class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({super.key, this.onSurface = false});

  /// Si [onSurface] es true, usa colores oscuros (para fondo blanco).
  /// Si es false, usa colores claros (para barra superior azul/oscura).
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleService.instance,
      builder: (context, current, _) {
        return PopupMenuButton<AppLanguage>(
          onSelected: LocaleService.instance.setLanguage,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          offset: const Offset(0, 44),
          itemBuilder: (_) => AppLanguage.values
              .map((lang) => PopupMenuItem<AppLanguage>(
                    value: lang,
                    child: Row(
                      children: [
                        Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          lang.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (lang == current) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ))
              .toList(),
          child: _FlagChip(flag: current.flag, onSurface: onSurface),
        );
      },
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.flag, required this.onSurface});
  final String flag;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: onSurface
            ? const Color(0xFFF0F2F6)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onSurface
              ? const Color(0xFFDDE1E9)
              : Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 20)),
    );
  }
}
