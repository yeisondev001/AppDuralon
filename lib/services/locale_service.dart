import 'package:flutter/foundation.dart';

enum AppLanguage { es, en, fr }

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

class LocaleService extends ValueNotifier<AppLanguage> {
  LocaleService._() : super(AppLanguage.es);
  static final LocaleService instance = LocaleService._();

  AppLanguage get language => value;
  void setLanguage(AppLanguage lang) => value = lang;
}
