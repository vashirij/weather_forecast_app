// ...existing code...
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:weather_forecast_app/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';

class AuthController {
  final fb.FirebaseAuth _auth;

  AuthController({fb.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  // === Email/Password Signup ===
  Future<User> signup(
    String email,
    String password,
    String phone, {
    String firstName = '',
    String lastName = '',
  }) async {
    if (email.isEmpty) throw Exception('Email cannot be empty');
    if (password.length < 6) throw Exception('Password too weak');

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) throw Exception('Signup failed');

      return User(
        email: fbUser.email ?? email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Signup failed');
    }
  }

  // === Phone OTP Login (placeholder) ===
  Future<User> loginWithPhone(String otp) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (otp.isEmpty) throw Exception('OTP required');
    if (otp == 'VALID_OTP') return User(phone: otp, email: '');
    if (otp == 'EXPIRED_OTP') throw Exception('Invalid or expired OTP');

    return User(phone: otp, email: '');
  }

  // === Email/Password Login ===
  Future<User> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password required');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      throw Exception('Invalid email format');
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) throw Exception('Login failed');

      return User(
        email: fbUser.email ?? email,
        phone: fbUser.phoneNumber ?? '',
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // === Logout ===
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Sign out user, clear prefs and local DB cache.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // ignore firebase sign out errors
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await DBService().clearAllData();
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email via Firebase Auth.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send password reset email');
    }
  }
}