import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_flow.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/pages/login_screen.dart';
import 'package:app_duralon/services/auth_service.dart';

/// Pantalla de arranque: espera a que Firebase restaure la sesión guardada y
/// navega al destino correcto sin que el usuario tenga que iniciar sesión de nuevo.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  Future<void> _navigate() async {
    // Web: procesa cualquier resultado de signInWithRedirect pendiente.
    if (kIsWeb) {
      try {
        final result = await FirebaseAuth.instance.getRedirectResult();
        if (result.user != null) {
          await _routeForUser(result.user!);
          return;
        }
      } catch (_) {}
    }

    // Espera la primera emisión del estado de autenticación (restaurado de
    // localStorage / IndexedDB en web, o Keychain en móvil).
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) return;

    if (user == null) {
      _replace(const LoginScreen());
    } else {
      await _routeForUser(user);
    }
  }

  Future<void> _routeForUser(User user) async {
    final isGoogle =
        user.providerData.any((p) => p.providerId == 'google.com');

    bool needsOnboarding = false;
    if (isGoogle) {
      needsOnboarding = await AuthService().needsGoogleOnboarding(user);
    }

    if (!mounted) return;
    _replace(
      needsOnboarding
          ? const OnboardingFlow()
          : const HomeScreen(isGuestMode: false),
    );
  }

  void _replace(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
