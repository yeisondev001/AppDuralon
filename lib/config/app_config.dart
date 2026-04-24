// =============================================================================
// Configuración global: modo prueba (mock, sin API) vs producción (backend real).
//
// Cómo usar al conectar el backend:
// 1. Cambia [environment] a [AppEnvironment.production] en releases.
// 2. Sustituye [apiBaseUrl] por la URL real (o usa --dart-define / flavor).
// 3. [useMockCatalog] será false; carga productos con HTTP y mapea a [Product].
// 4. El tipo de usuario: usa [UserAccountType] con datos del token / perfil
//    (ej. campo `is_test` o `account_tier` del JSON). [isGuestMode] en [HomeScreen]
//    pasa a derivarse de `session.isGuest` o equivalente.
// =============================================================================

/// Entorno de ejecución de la app.
enum AppEnvironment {
  /// Mock, carrito restringido para invitado, catálogo local.
  demo,

  /// API real, autenticación y cuentas según el servidor.
  production,
}

class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // Punto único: cambia solo esto al pasar a tienda en vivo (o usa flavors).
  // ---------------------------------------------------------------------------
  static const AppEnvironment environment = AppEnvironment.demo;

  static bool get isDemoMode => environment == AppEnvironment.demo;
  static bool get isProduction => environment == AppEnvironment.production;

  /// Catálogo desde [mock_products] / lógica local. En producción, false → API.
  static bool get useMockCatalog => isDemoMode;

  /// Llamadas HTTP (cuando conectes el backend). Ahora no se usa; doc para URL única.
  static String get apiBaseUrl {
    if (isProduction) {
      return 'https://api.tu-duralon.com'; // Sustituir por URL real
    }
    return 'http://localhost:0'; // Demo: no se llama; evita null
  }
}

// -----------------------------------------------------------------------------
// Modelo de cuenta para alinear con el backend (no sustituye aún a [isGuestMode]).
// Asigna según login: guest | test | customer.
// -----------------------------------------------------------------------------
enum UserAccountType {
  /// Sin sesión (invitado).
  guest,

  /// Cuenta de pruebas / QA (mapear desde API, p. ej. `account_type: "test"`).
  test,

  /// Cliente con cuenta real.
  customer,
}
