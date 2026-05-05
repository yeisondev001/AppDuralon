import 'package:flutter/widgets.dart';

/// Singleton que gestiona el idioma activo y sus traducciones.
/// Usa [LocaleScope] (InheritedNotifier) para propagar cambios a toda la UI.
class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  String _lang = 'es';
  String get lang => _lang;

  void setLang(String lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }

  String t(String key) =>
      (_strings[_lang] ?? _strings['es']!)[key] ??
      _strings['es']![key] ??
      key;

  static const Map<String, Map<String, String>> _strings = {
    'es': {
      // Login
      'welcome': '¡Bienvenido!',
      'continue_google': 'Continuar con Google',
      'continue_apple': 'Continuar con Apple',
      'browse_guest': 'Echar un vistazo como invitado',
      'continue_guest': 'Continuar como invitado',
      'connecting': 'Conectando...',
      // Header
      'search_hint': 'Buscar productos',
      'cart_tooltip': 'Carrito',
      // Tabs
      'tab_hogar': 'HOGAR',
      'tab_industrial': 'INDUSTRIAL',
      'all_categories': 'TODAS LAS CATEGORÍAS',
      // Catálogo standalone
      'catalog_title': 'Catálogo',
      'filter_hint': 'Filtrar por nombre de sección...',
      'no_products': 'No se encontraron productos con esa búsqueda.',
      'search_results_prefix': 'Resultados para',
      // Botones de sección
      'ver_todos': 'Ver todos',
      // Menú lateral (las claves son los identificadores que HomeScreen compara)
      'Inicio': 'Inicio',
      'Catalogo': 'Catálogo',
      'Mi perfil': 'Mi perfil',
      'Ofertas': 'Ofertas',
      'Mis pedidos': 'Mis pedidos',
      'Mis direcciones': 'Mis direcciones',
      'Metodos de pago': 'Métodos de pago',
      'Soporte': 'Soporte',
      'Reglas mayoristas': 'Reglas mayoristas',
      'Panel de administración': 'Panel de administración',
      'Cerrar sesión': 'Cerrar sesión',
      'Iniciar sesion': 'Iniciar sesión',
      'Términos y condiciones': 'Términos y condiciones',
      'Quiénes somos': 'Quiénes somos',
    },
    'en': {
      'welcome': 'Welcome!',
      'continue_google': 'Continue with Google',
      'continue_apple': 'Continue with Apple',
      'browse_guest': 'Browse as guest',
      'continue_guest': 'Continue as guest',
      'connecting': 'Connecting...',
      'search_hint': 'Search products',
      'cart_tooltip': 'Cart',
      'tab_hogar': 'HOME',
      'tab_industrial': 'INDUSTRIAL',
      'all_categories': 'ALL CATEGORIES',
      'catalog_title': 'Catalogue',
      'filter_hint': 'Filter by section name...',
      'no_products': 'No products found for that search.',
      'search_results_prefix': 'Results for',
      'ver_todos': 'View all',
      'Inicio': 'Home',
      'Catalogo': 'Catalogue',
      'Mi perfil': 'My Profile',
      'Ofertas': 'Offers',
      'Mis pedidos': 'My Orders',
      'Mis direcciones': 'My Addresses',
      'Metodos de pago': 'Payment Methods',
      'Soporte': 'Support',
      'Reglas mayoristas': 'Wholesale Rules',
      'Panel de administración': 'Admin Panel',
      'Cerrar sesión': 'Log out',
      'Iniciar sesion': 'Log in',
      'Términos y condiciones': 'Terms and Conditions',
      'Quiénes somos': 'About us',
    },
    'fr': {
      'welcome': 'Bienvenue !',
      'continue_google': 'Continuer avec Google',
      'continue_apple': 'Continuer avec Apple',
      'browse_guest': "Parcourir en tant qu'invité",
      'continue_guest': "Continuer en tant qu'invité",
      'connecting': 'Connexion...',
      'search_hint': 'Rechercher des produits',
      'cart_tooltip': 'Panier',
      'tab_hogar': 'MAISON',
      'tab_industrial': 'INDUSTRIEL',
      'all_categories': 'TOUTES LES CATÉGORIES',
      'catalog_title': 'Catalogue',
      'filter_hint': 'Filtrer par nom de section...',
      'no_products': 'Aucun produit trouvé pour cette recherche.',
      'search_results_prefix': 'Résultats pour',
      'ver_todos': 'Voir tout',
      'Inicio': 'Accueil',
      'Catalogo': 'Catalogue',
      'Mi perfil': 'Mon profil',
      'Ofertas': 'Offres',
      'Mis pedidos': 'Mes commandes',
      'Mis direcciones': 'Mes adresses',
      'Metodos de pago': 'Modes de paiement',
      'Soporte': 'Assistance',
      'Reglas mayoristas': 'Règles de gros',
      'Panel de administración': "Panneau d'administration",
      'Cerrar sesión': 'Se déconnecter',
      'Iniciar sesion': 'Se connecter',
      'Términos y condiciones': 'Conditions générales',
      'Quiénes somos': 'Qui sommes-nous',
    },
  };
}

/// InheritedNotifier que propaga cambios de [AppLocale] a todos los widgets
/// descendientes que registren dependencia vía [LocaleScope.tr] o [LocaleScope.lang].
class LocaleScope extends InheritedNotifier<AppLocale> {
  LocaleScope({super.key, required super.child})
      : super(notifier: AppLocale.instance);

  /// Traduce [key] al idioma activo y registra al widget llamante como dependiente
  /// para que se reconstruya automáticamente al cambiar el idioma.
  static String tr(BuildContext context, String key) {
    context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    return AppLocale.instance.t(key);
  }

  /// Devuelve el código de idioma activo ('es', 'en', 'fr') y registra dependencia.
  static String lang(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    return AppLocale.instance.lang;
  }
}
