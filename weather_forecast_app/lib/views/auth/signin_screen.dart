import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import '../../utils/helpers.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authController = AuthController();

  bool _isLoading = false;

  // === Helper to toggle loading ===
  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  // === Email/Password login ===
  Future<void> _signin() async {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
      try {
        final user = await _authController.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        Helpers.showSnackBar(context, "Welcome back ${user.email}");
        Navigator.pushReplacementNamed(context, '/dailyForecast');
      } catch (e) {
        Helpers.showSnackBar(context, "Sign in failed: $e", isError: true);
      } finally {
        _setLoading(false);
      }
    }
  }

  // === Google OAuth login ===
  Future<void> _signinWithGoogle() async {
    _setLoading(true);
    try {
      final user = await _authController.loginWithGoogle();
      Helpers.showSnackBar(
        context,
        "Google sign-in successful: ${user.email ?? 'Unknown'}",
      );
      Navigator.pushReplacementNamed(context, '/dailyForecast');
    } catch (e) {
      Helpers.showSnackBar(context, "Google sign-in failed: $e", isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // === Phone OTP login ===
  Future<void> _signinWithPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, "Enter phone number/OTP", isError: true);
      return;
    }

    _setLoading(true);
    try {
      final user = await _authController.loginWithPhone(
        _phoneController.text.trim(),
      );
      Helpers.showSnackBar(
        context,
        "Phone OTP sign-in successful: ${user.phone ?? 'Unknown'}",
      );
      Navigator.pushReplacementNamed(context, '/dailyForecast');
    } catch (e) {
      Helpers.showSnackBar(
        context,
        "Phone OTP sign-in failed: $e",
        isError: true,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _forgotPassword() => Navigator.pushNamed(context, '/forgotPassword');

  void _goToSignup() => Navigator.pushNamed(context, '/signup');

  // === Validators ===
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Enter email";
    if (!value.contains("@")) return "Enter valid email";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Enter password";
    if (value.length < 8) return "Password too short (min 8 chars)";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // === Email field ===
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),

                  // === Password field ===
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _signin,
                    child: const Text("Sign In"),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _signinWithGoogle,
                    icon: Image.asset(
                      "images/google_logo.png",
                      height: 20,
                      width: 20,
                    ),
                    label: const Text("Sign In with Google"),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: _signinWithPhone,
                    icon: const Icon(Icons.phone_android),
                    label: const Text("Sign In with Phone OTP"),
                  ),
                  const SizedBox(height: 20),

                  // Forgot password
                  TextButton(
                    onPressed: _forgotPassword,
                    child: const Text("Forgot Password?"),
                  ),

                  // Navigate to Signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account?"),
                      TextButton(
                        onPressed: _goToSignup,
                        child: const Text("Sign Up"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // === Loading Overlay ===
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
