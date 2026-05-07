// Generado por FlutterFire CLI. No editar manualmente.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Devuelve las credenciales Firebase correctas según la plataforma en ejecución.
// Firebase.initializeApp() llama a currentPlatform en main.dart.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // kIsWeb se evalúa primero porque en navegador defaultTargetPlatform no es confiable.
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      // Windows no tiene SDK nativo de Firebase; reutiliza la config Web.
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Credenciales del google-services.json de Android.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBikChu5xBsW0nIbqiTuRyw6JHvpd2lo6Q',
    appId: '1:383683295145:android:baef81289eb53114b536b8',
    messagingSenderId: '383683295145',
    projectId: 'appduralon',
    storageBucket: 'appduralon.firebasestorage.app',
  );

  // Credenciales del GoogleService-Info.plist de iOS.
  // iosClientId lo usa Google Sign-In para el flujo OAuth nativo en iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC55m8Czv09qQzmW4rOeN5-GC5SXaYDHlY',
    appId: '1:383683295145:ios:3f0ef9c7ad1b218eb536b8',
    messagingSenderId: '383683295145',
    projectId: 'appduralon',
    storageBucket: 'appduralon.firebasestorage.app',
    iosClientId: '383683295145-fasjrf9b65o17kgd5qlj9edbvl3pp0hc.apps.googleusercontent.com',
    iosBundleId: 'com.example.appDuralon',
  );

  // Credenciales de la app Web registrada en Firebase Console.
  // authDomain maneja los popups de Google Sign-In en el navegador.
  // measurementId vincula Google Analytics al proyecto.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjN9UUKo503SwrXkVVRgrGy4UwtTOlbhk',
    appId: '1:383683295145:web:03b54cdc944c598bb536b8',
    messagingSenderId: '383683295145',
    projectId: 'appduralon',
    authDomain: 'appduralon.firebaseapp.com',
    storageBucket: 'appduralon.firebasestorage.app',
    measurementId: 'G-XHBHHJ4RR9',
  );

  // Windows reutiliza la config Web (generado así por FlutterFire CLI).
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDjN9UUKo503SwrXkVVRgrGy4UwtTOlbhk',
    appId: '1:383683295145:web:03b54cdc944c598bb536b8',
    messagingSenderId: '383683295145',
    projectId: 'appduralon',
    authDomain: 'appduralon.firebaseapp.com',
    storageBucket: 'appduralon.firebasestorage.app',
    measurementId: 'G-XHBHHJ4RR9',
  );
}
