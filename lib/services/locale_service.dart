import 'package:flutter/foundation.dart';

// Idiomas soportados en la app. Añadir aquí + en AppLanguageExt + en app_strings.dart.
enum AppLanguage { es, en, fr }

// Datos de presentación del idioma (bandera y nombre legible).
extension AppLanguageExt on AppLanguage {
  String get flag => const {
    AppLanguage.es: '🇪🇸',
    AppLanguage.en: '🇺🇸',
    AppLanguage.fr: '🇫🇷',
  }[this]!;

  String get label => const {
    AppLanguage.es: 'Español',
    AppLanguage.en: 'English',
    AppLanguage.fr: 'Français',
  }[this]!;
}

// Singleton que mantiene el idioma activo en memoria.
// Extiende ValueNotifier para que cualquier widget pueda escuchar cambios
// sin necesidad de setState ni rebuild del árbol completo.
class LocaleService extends ValueNotifier<AppLanguage> {
  LocaleService._() : super(AppLanguage.es);
  static final LocaleService instance = LocaleService._();

  AppLanguage get language => value;
  void setLanguage(AppLanguage lang) => value = lang;
}
