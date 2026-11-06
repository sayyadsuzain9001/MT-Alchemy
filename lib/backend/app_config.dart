import 'package:firebase_core/firebase_core.dart';

/// Build-time configuration, supplied with
/// `flutter run --dart-define-from-file=config/app_env.json`.
///
/// When no Firebase API key is supplied the app talks to the local Firebase
/// Emulator Suite using the offline-only `demo-mtalchemy` project, so the
/// whole platform can be developed and tested without a cloud project.
class AppConfig {
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'demo-mtalchemy',
  );
  static const firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:000000000000:web:0000000000000000000000',
  );
  static const firebaseSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '000000000000',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  /// Host for the Firebase emulators (Auth 9099, Firestore 8080).
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// Google AI Studio key for the Gemini chatbot. Optional: without it the
  /// assistant answers from its built-in MT Alchemy knowledge base.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  /// Shows one-tap demo account chips on the sign-in page.
  static const showDemoAccounts = bool.fromEnvironment(
    'SHOW_DEMO_ACCOUNTS',
    defaultValue: true,
  );

  /// Base URL of payments_server (Stripe). Empty = built-in test gateway.
  static const paymentsApiUrl = String.fromEnvironment('PAYMENTS_API_URL');

  static bool get useEmulator =>
      firebaseApiKey.isEmpty ||
      const bool.fromEnvironment('USE_FIREBASE_EMULATOR');

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: firebaseApiKey.isEmpty ? 'demo-api-key' : firebaseApiKey,
    appId: firebaseAppId,
    messagingSenderId: firebaseSenderId,
    projectId: firebaseProjectId,
    authDomain: firebaseAuthDomain.isEmpty
        ? '$firebaseProjectId.firebaseapp.com'
        : firebaseAuthDomain,
    storageBucket: firebaseStorageBucket.isEmpty ? null : firebaseStorageBucket,
  );
}
