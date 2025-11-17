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

  static bool doPasswordsMatch(String password, String confirmPassword) {
    return password.trim() == confirmPassword.trim();
  }

  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  static bool isValidPhone(String phone) {
    // Basic phone validation - at least 10 digits
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 10;
  }
}
