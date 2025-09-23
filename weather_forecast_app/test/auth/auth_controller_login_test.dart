import 'package:flutter_test/flutter_test.dart';
import 'package:weather_forecast_app/controllers/auth_controller.dart';
import 'package:weather_forecast_app/models/user.dart';

void main() {
  late AuthController controller;

  setUp(() {
    controller = AuthController();
  });
  group("Login Feature - Story 1", () {
    // === Email & Password ===
    test("Login succeeds with valid email & password", () async {
      final user = await controller.login("valid@email.com", "StrongPass123!");
      expect(user, isA<User>());
      expect(user.email, "valid@email.com");
    });

    test("Login fails with wrong password", () async {
      expect(
        () => controller.login("valid@email.com", "WrongPass"),
        throwsA(predicate((e) => e.toString().contains("Invalid password"))),
      );
    });

    // === Empty credentials ===
        test("Login fails with empty credentials", () async {
      expect(
        () => controller.login("", ""),
        throwsA(predicate((e) => e.toString().contains("Email and password required"))),
      );
    });
        // === Invalid email ===
    test("Login fails with invalid email format", () async {
      expect(
        () => controller.login("invalid-email", "Password123!"),
        throwsA(predicate((e) => e.toString().contains("Invalid email"))),
      );
    });
    // === Null email ===
    test("Login fails when email is empty", () async {
      expect(
        () => controller.login("", "StrongPass123!"),
        throwsA(isA<Exception>()),
      );
    });
    // === Google OAuth ===
    test("Login with Google OAuth works", () async {
      final user = await controller.loginWithGoogle();
      expect(user, isA<User>());
      expect(user.email, contains("@"));
    });

    // === Phone OTP ===
    test("Login succeeds with valid phone OTP", () async {
      final user = await controller.loginWithPhone("VALID_OTP");
      expect(user.phone, "VALID_OTP");
    });

    test("Login fails with expired OTP", () async {
      expect(
        () => controller.loginWithPhone("EXPIRED_OTP"),
        throwsA(predicate((e) => e.toString().contains("Invalid or expired OTP"))),
      );
    });

    test("Login fails with empty OTP", () async {
      expect(
        () => controller.loginWithPhone(""),
        throwsA(predicate((e) => e.toString().contains("OTP required"))),
      );
    });

  });
}
