import 'package:flutter_test/flutter_test.dart';
import 'package:weather_forecast_app/controllers/auth_controller.dart';
import 'package:weather_forecast_app/models/user.dart';

void main() {
  final controller = AuthController();

  group("Signup Feature - Story 2", () {
    test("Signup succeeds with valid email and password", () async {
      final user = await controller.signup("valid@email.com", "StrongPass123!", "1234567890");
      expect(user, isA<User>());
      expect(user.email, "valid@email.com");
    });

    test("Signup fails with empty email", () async {
      expect(
        () => controller.signup("", "StrongPass123!", "1234567890"),
        throwsException,
      );
    });

    test("Signup fails with weak password", () async {
      expect(
        () => controller.signup("weak@email.com", "123", "1234567890"),
        throwsException,
      );
    });

    test("Signup with Google returns a valid user", () async {
      final user = await controller.signupWithGoogle();
      expect(user, isA<User>());
      expect(user.email, contains("@"));
    });

    test("Signup with phone OTP succeeds for valid OTP", () async {
      final user = await controller.signup("otp@email.com", "Pass1234!", "VALID_OTP");
      expect(user.phone, "VALID_OTP");
    });

    test("Signup with phone OTP fails for expired OTP", () async {
      expect(
        () => controller.signup("otp@email.com", "Pass1234!", "EXPIRED_OTP"),
        throwsException,
      );
    });
  });
}
