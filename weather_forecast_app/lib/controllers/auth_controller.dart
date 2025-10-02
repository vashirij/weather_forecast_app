import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:weather_forecast_app/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AuthController {
  GoogleSignIn get googleSignIn => _googleSignIn;
  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthController({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    String? clientId,
  }) : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn =
           googleSignIn ??
           (kIsWeb
               ? GoogleSignIn(
                   clientId:
                       clientId ??
                       'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
                 )
               : GoogleSignIn());

  // === Email/Password Signup ===
  Future<User> signup(
    String email,
    String password,
    String phone, {
    String firstName = '',
    String lastName = '',
  }) async {
    if (email.isEmpty) throw Exception("Email cannot be empty");
    if (password.length < 6) throw Exception("Password too weak");

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) throw Exception("Signup failed");

      return User(
        email: fbUser.email ?? email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Signup failed");
    }
  }

  // === Google Signup (same as login, first-time users are auto-created) ===
  Future<User> signupWithGoogle() async {
    return loginWithGoogle();
  }

  // === Google Login ===
  Future<User> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception("Sign-in aborted by user");

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final fb.User? fbUser = userCredential.user;

      if (fbUser == null) throw Exception("Google sign-in failed");

      return User(
        email: fbUser.email ?? "unknown",
        phone: fbUser.phoneNumber ?? "",
      );
    } catch (e) {
      throw Exception("Google login failed: $e");
    }
  }

  // === Phone OTP Login (placeholder, extend later with Firebase PhoneAuth) ===
  Future<User> loginWithPhone(String otp) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (otp.isEmpty) throw Exception("OTP required");
    if (otp == "VALID_OTP") return User(phone: otp, email: "");
    if (otp == "EXPIRED_OTP") throw Exception("Invalid or expired OTP");

    return User(phone: otp, email: "");
  }

  // === Email/Password Login ===
  Future<User> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception("Email and password required");
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      throw Exception("Invalid email format");
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = userCredential.user;
      if (fbUser == null) throw Exception("Login failed");

      return User(
        email: fbUser.email ?? email,
        phone: fbUser.phoneNumber ?? "",
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  // === Logout ===
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Sign out user. Call provider-specific sign-out logic (Firebase/Auth + Google).
  Future<void> signOut() async {
    // Sign out from Firebase Auth if available
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      // ignore errors from firebase sign out
    }

    // Sign out from Google Sign-In if available
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // ignore errors from google sign out
    }
  }

  /// Send password reset email via Firebase Auth.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );
    } catch (e) {
      // propagate so callers can show an error
      rethrow;
    }
  }
}
