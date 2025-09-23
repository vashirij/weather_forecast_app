import 'package:weather_forecast_app/models/user.dart';

class AuthController {
  Future<User> signup(String email, String password, String phone) async {
    // Add your signup logic here, for now return a dummy user for testing
    if (email.isEmpty) throw Exception("Email cannot be empty");
    if (password.length < 6) throw Exception("Password too weak");
    if (phone == "EXPIRED_OTP") throw Exception("OTP expired");
    return User(email: email, phone: phone);
  }

  Future<User> signupWithGoogle() async {
    // Dummy implementation for testing
    return User(email: "googleuser@email.com", phone: "google_phone");
  }

  Future<User> loginWithGoogle() async {
    // TODO: Implement Google sign-in logic here and return a User object.
    // For now, return a dummy user for compilation.
    return User(email: "dummy@gmail.com", phone: "0000000000");
  }

  Future<User> loginWithPhone(String otp) async {
    // Simulate phone OTP login
    await Future.delayed(Duration(milliseconds: 100));
    if (otp == "EXPIRED_OTP") {
      throw Exception("Invalid or expired OTP");
    }
    return User(phone: otp, email: '');
  }

  Future<User> login(String email, String password) async {
    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      throw Exception("Invalid email");
    }
    // Simulate login logic
    if (email == "valid@email.com" && password == "StrongPass123!") {
      return User(email: email, phone: '');
    }
    if (email == "valid@email.com" && password != "StrongPass123!") {
      throw Exception("Invalid password");
    }
    throw Exception("User not found");
  }
}
