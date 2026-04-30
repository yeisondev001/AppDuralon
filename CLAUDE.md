# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Existe un `CLAUDE.md` adicional en el directorio padre (`../CLAUDE.md`) con un levantamiento detallado del dominio (modelos, colecciones Firestore, roles, pendientes). Este archivo es complementario y se enfoca en comandos y arquitectura no obvia. Lee el padre para contexto de producto.

## Comandos comunes

```bash
# Instalar dependencias
flutter pub get

# Ejecutar (móvil/emulador conectado)
flutter run

# Ejecutar en Web (Chrome)
flutter run -d chrome

# Lint / análisis estático
flutter analyze

# Tests
flutter test                           # toda la suite
flutter test test/widget_test.dart     # un archivo
flutter test --plain-name "nombre"     # filtrado por nombre

# Builds release
flutter build apk        # Android
flutter build ipa        # iOS
flutter build web        # Web

# Regenerar íconos de launcher (tras cambiar duralon_logo.png)
dart run flutter_launcher_icons

# Firebase
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
# Windows + PowerShell: usar `firebase.cmd ...` o `npx firebase-tools ...`
```

### Scripts de mantenimiento (uso puntual, no parte del runtime)

- `lib/migrate_prices_main.dart` — entry point alternativo que lee un CSV (`codigo,precio`) y actualiza el campo `precio` en `products`, eliminando el legacy `price`. Ejecutar con `dart run lib/migrate_prices_main.dart`. Requiere Firebase configurado para Windows en `firebase_options.dart`.
- `scripts/update_prices_from_csv.js` — equivalente Node.js (usa `node_modules/` en la raíz; corrió `npm install` allí).
- `bin/` y `scripts/` contienen utilidades sueltas; nada de esto se empaqueta en la app.

### Modo demo vs producción

Un único interruptor en [lib/config/app_config.dart](lib/config/app_config.dart): `AppConfig.environment = AppEnvironment.production`. Cambia ahí para activar mocks. `useMockCatalog` siempre es `false` cuando es `production` — los datos vienen de Firestore. `apiBaseUrl` apunta a `https://api.tu-duralon.com` pero **no hay backend HTTP usándose hoy**; toda la persistencia es Firestore.

## Arquitectura

### Estado y datos
- **Sin librería de estado global.** Todo es `setState` + `StreamBuilder` sobre Firestore. No introducir Riverpod/Bloc/Provider sin acuerdo explícito.
- **Firebase es la única fuente de verdad.** `cloud_firestore` con streams en tiempo real para `products`, `catalog_categories`, `users`. `streamAll()` filtra `isActive == true`; `streamAdmin()` trae todos. El backend HTTP declarado en `AppConfig` es aspiracional.
- **Nombres de campos en Firestore están en español** (`nombre`, `correo`, `rol`, `tipoContribuyente`, `direccionFiscal`, `creadoEn`…). Ver [lib/services/auth_service.dart](lib/services/auth_service.dart) como referencia canónica del esquema escrito por la app — `README.md` y el CLAUDE.md padre describen un esquema en inglés que está parcialmente desactualizado respecto al código actual.

### Flujo de autenticación (no obvio)
1. `LoginScreen` ofrece 4 caminos: email/password, Google, Apple, invitado (`isGuestMode: true`).
2. Tras login con Google, `AuthService.needsGoogleOnboarding(user)` consulta `customers/{uid}` y devuelve `true` si faltan campos clave **o** la identificación dominicana no valida (RNC 9 dígitos con pesos `[7,9,8,6,5,4,3,2]` o cédula 11 dígitos mod-10).
3. Si falta onboarding → `OnboardingFlow` (en [lib/pages/google_onboarding/](lib/pages/google_onboarding/)) navega manualmente paso a paso (Step1 → Step2 → …). **No hay router**; cada step `Navigator.push` al siguiente y comparte un `RegistroClienteModel` (alias `OnboardingData`) por referencia. La numeración de archivos `step_N_*.dart` está en transición — hay nombres viejos (`step_3_tax_id.dart`, etc.) marcados como borrados en `git status` y nuevos (`step_1_identity.dart`, `step_2_location.dart`) sin renumerar; revisar las clases reales antes de inferir orden por nombre de archivo.
4. **Web vs móvil** en Google Sign-In: Web usa `FirebaseAuth.signInWithPopup(GoogleAuthProvider)` directamente; móvil usa `google_sign_in: ^7.2.0` (`GoogleSignIn.instance.authenticate()` — API nueva, sin `signIn()`/`disconnect()` legacy). El `serverClientId` (Web client ID) y el `iosClientId` están hardcoded en [lib/main.dart](lib/main.dart).

### Roles y autorización
Definidos en [firestore.rules](firestore.rules) — son la fuente de verdad de permisos:
- `cliente_minorista`, `cliente_distribuidor` → agrupados como `isCliente()`
- `vendedor`, `admin` → agrupados como `isInterno()`
- `admin` único con permiso de borrado en `users`/`customers`/`products`
- `products` y `catalog_categories` tienen **lectura pública** (catálogo accesible sin sesión, modo invitado depende de esto)
- `orders`: cliente puede editar solo si `status == 'pendiente'`

Cualquier nuevo rol requiere actualizar tanto el código Dart como las reglas Firestore en simultáneo, o el cliente verá `permission-denied`.

### Modelo de productos
- `Product.variants: List<ProductVariant>` está **embebido** en el documento de Firestore (no es subcolección). Modificar variantes implica reescribir el array completo.
- `tab: 'hogar' | 'industrial'` segmenta el catálogo en dos pestañas en `HomeScreen`. `catalogId` enlaza al doc en `catalog_categories`.
- Los seeders en [lib/services/product_seeder.dart](lib/services/product_seeder.dart) (`seedCatalogHogar2026`, `seedCatalogIndustrial2025`) son **destructivos** — sobreescriben datos. Se invocan desde el panel admin pestaña "Catálogos" y nunca deberían correrse en producción accidentalmente.

### Crashlytics
- Solo móvil (`if (!kIsWeb)` en [lib/main.dart](lib/main.dart)).
- Captura tanto errores del framework Flutter (`FlutterError.onError`) como async fuera del framework (`PlatformDispatcher.instance.onError`).
- Habilitado en todos los modos para poder probar desde el panel admin → pestaña "Pruebas". Al pasar a release real, considerar `setCrashlyticsCollectionEnabled(!kDebugMode)`.

### Convenciones del repo
- Lints: `package:flutter_lints/flutter.yaml` sin overrides.
- SDK: Dart `^3.11.5`. Si el código usa `late`/`required`/null safety, asumir Dart 3.
- Plataformas activas: Android, iOS, Web. Windows/macOS/Linux compilan pero no son objetivos de release.
- Assets: solo `assets/images/duralon_logo.png` está declarado en `pubspec.yaml`. Si añades una imagen y no aparece, declárala explícitamente.

## Pendientes conocidos (del CLAUDE.md padre)
Carrito y checkout son solo stubs (ver [lib/widgets/duralon_guest_cart_dialog.dart](lib/widgets/duralon_guest_cart_dialog.dart)). El `AdminPanelScreen` borra el doc Firestore del usuario pero **no la cuenta de Firebase Auth** — queda huérfana. No hay notificaciones push ni gestión de pedidos.
