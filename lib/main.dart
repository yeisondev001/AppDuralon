import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_duralon/config/app_locale.dart';
import 'package:app_duralon/pages/auth_gate.dart';
import 'firebase_options.dart';

// Web client ID (serverClientId para Android, también usado en iOS).
// Extraído de android/app/google-services.json → oauth_client[client_type=3].
const String _kGoogleWebClientId =
    '383683295145-9q5mcj41v9lqqragski0fc99t701shhe.apps.googleusercontent.com';

// iOS client ID — tomado de firebase_options.dart → FirebaseOptions.ios.iosClientId.
const String _kGoogleIosClientId =
    '383683295145-fasjrf9b65o17kgd5qlj9edbvl3pp0hc.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics ───────────────────────────────────────────────────────────
  // Crashlytics solo disponible en móvil (no en web).
  if (!kIsWeb) {
    // Habilitado en todos los modos para poder probar desde el panel de admin.
    // Cuando la app pase a producción, cambiar a: !kDebugMode
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(true);

    // Captura errores del framework Flutter (widgets, rendering, etc.).
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Captura errores async fuera del framework (Isolate raíz, futures sin catch).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Inicializar Google Sign-In (google_sign_in 7.x).
  // En web se omite: Firebase maneja el popup directamente con signInWithPopup.
  if (!kIsWeb) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    await GoogleSignIn.instance.initialize(
      // clientId: requerido en iOS para identificar la app ante Google.
      clientId: isIos ? _kGoogleIosClientId : null,
      // serverClientId: requerido en Android para obtener el idToken.
      // En iOS también puede pasarse para acceso a APIs del lado servidor.
      serverClientId: _kGoogleWebClientId,
    );
  }

  runApp(const AppDuralon());
}

class AppDuralon extends StatelessWidget {
  const AppDuralon({super.key});

  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver analyticsObserver =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plasticos Duralon',
        navigatorObservers: <NavigatorObserver>[analyticsObserver],
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF5F6FA),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
