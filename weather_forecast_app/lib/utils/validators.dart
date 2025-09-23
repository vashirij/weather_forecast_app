class Validators {
  static bool isValidEmail(String email) {
    // Simple email validation regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // Example: password must be at least 6 characters
    return password.length >= 6;
  }
}
