import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Signed-in identity as seen by the app, independent of Firebase types.
class AuthUser {
  const AuthUser({required this.uid, required this.email});
  final String uid;
  final String email;
}

/// A sign-in or registration failure with a message that is safe to show.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin seam over the identity provider so widget tests can run without a
/// Firebase project.
abstract class AuthGateway {
  AuthUser? get currentUser;
  Future<AuthUser> signIn(String email, String password);
  Future<AuthUser> register(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String current, String next);

  /// Creates a sign-in for someone else (admin) without changing the
  /// current session. Returns the new user's uid.
  Future<String> createAccountForOther(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);
  final FirebaseAuth _auth;

  AuthUser? _map(User? user) => user == null
      ? null
      : AuthUser(uid: user.uid, email: (user.email ?? '').toLowerCase());

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  static String friendlyMessage(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' => 'This account has been disabled. Contact MT Alchemy.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => 'Email or password is incorrect.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Choose a stronger password (at least 8 characters).',
    'too-many-requests' => 'Too many attempts. Wait a moment, then try again.',
    'network-request-failed' =>
      'Cannot reach the sign-in service. Check your connection.',
    _ => 'Sign-in failed (${e.code}). Please try again.',
  };

  Future<AuthUser> _guard(Future<UserCredential> Function() action) async {
    try {
      final credential = await action();
      return _map(credential.user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyMessage(e));
    } catch (_) {
      throw const AuthFailure(
        'Cannot reach the sign-in service. Check your connection.',
      );
    }
  }

  @override
  Future<AuthUser> signIn(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    ),
  );

  @override
  Future<AuthUser> register(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    ),
  );

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      // Do not reveal whether an account exists.
      if (e.code != 'user-not-found') throw AuthFailure(friendlyMessage(e));
    }
  }

  @override
  Future<void> changePassword(String current, String next) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthFailure('Sign in again to change your password.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: current),
      );
      await user.updatePassword(next);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Your current password is incorrect.'
            : friendlyMessage(e),
      );
    }
  }

  @override
  Future<String> createAccountForOther(String email, String password) async {
    // A secondary Firebase app keeps the admin signed in on the main one.
    final name = 'account-admin-${DateTime.now().microsecondsSinceEpoch}';
    final app = await Firebase.initializeApp(
      name: name,
      options: AppConfig.firebaseOptions,
    );
    try {
      final auth = FirebaseAuth.instanceFor(app: app);
      if (AppConfig.useEmulator) {
        await auth.useAuthEmulator(AppConfig.emulatorHost, 9099);
      }
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = cred.user!.uid;
      await auth.signOut();
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(friendlyMessage(e));
    } finally {
      await app.delete();
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// In-memory identity provider used by automated tests.
class InMemoryAuthGateway implements AuthGateway {
  InMemoryAuthGateway([Map<String, String> passwords = const {}]) {
    passwords.forEach((email, password) {
      _accounts[email] = (password: password, uid: 'uid-$email');
    });
  }
  final Map<String, ({String password, String uid})> _accounts = {};
  AuthUser? _current;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    return _current = AuthUser(uid: account.uid, email: key);
  }

  @override
  Future<AuthUser> register(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('An account with this email already exists.');
    }
    if (password.length < 8) {
      throw const AuthFailure(
        'Choose a stronger password (at least 8 characters).',
      );
    }
    _accounts[key] = (password: password, uid: 'uid-$key');
    return _current = AuthUser(uid: 'uid-$key', email: key);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> changePassword(String current, String next) async {
    final user = _current;
    final account = user == null ? null : _accounts[user.email];
    if (user == null || account == null || account.password != current) {
      throw const AuthFailure('Your current password is incorrect.');
    }
    _accounts[user.email] = (password: next, uid: account.uid);
  }

  @override
  Future<String> createAccountForOther(String email, String password) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('An account with this email already exists.');
    }
    _accounts[key] = (password: password, uid: 'uid-$key');
    return 'uid-$key';
  }

  @override
  Future<void> signOut() async => _current = null;
}

/// Service locator for the database and identity provider.
class Backend {
  static FirebaseFirestore? _db;
  static AuthGateway? _auth;

  static FirebaseFirestore get db =>
      _db ?? (throw StateError('Backend.initialize() has not run.'));
  static AuthGateway get auth =>
      _auth ?? (throw StateError('Backend.initialize() has not run.'));
  static bool get isReady => _db != null && _auth != null;

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    if (AppConfig.useEmulator) {
      db.useFirestoreEmulator(AppConfig.emulatorHost, 8080);
      await auth.useAuthEmulator(AppConfig.emulatorHost, 9099);
    }
    if (kIsWeb) {
      await auth.setPersistence(Persistence.LOCAL);
    }
    _db = db;
    _auth = FirebaseAuthGateway(auth);
    // Restore a persisted session before the first frame.
    await auth.authStateChanges().first;
  }

  @visibleForTesting
  static void configure({
    required FirebaseFirestore db,
    required AuthGateway auth,
  }) {
    _db = db;
    _auth = auth;
  }
}
