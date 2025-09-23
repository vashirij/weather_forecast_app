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

  // === Email/Password login ===
  void _signin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        User user = await _authController.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        Helpers.showSnackBar(context, "Welcome back ${user.email}");
        Navigator.pushReplacementNamed(context, '/dailyForecast');
      } catch (e) {
        Helpers.showSnackBar(context, "Sign in failed: $e", isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // === Google OAuth login ===
  void _signinWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      User user = await _authController.loginWithGoogle();
      Helpers.showSnackBar(context, "Google sign-in successful: ${user.email}");
      Navigator.pushReplacementNamed(context, '/dailyForecast');
    } catch (e) {
      Helpers.showSnackBar(context, "Google sign-in failed: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // === Phone OTP login ===
  void _signinWithPhone() async {
    if (_phoneController.text.isEmpty) {
      Helpers.showSnackBar(context, "Enter phone number/OTP", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      User user = await _authController.loginWithPhone(
        _phoneController.text.trim(),
      );
      Helpers.showSnackBar(
        context,
        "Phone OTP sign-in successful: ${user.phone}",
      );
      Navigator.pushReplacementNamed(context, '/dailyForecast');
    } catch (e) {
      Helpers.showSnackBar(
        context,
        "Phone OTP sign-in failed: $e",
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // === Forgot Password ===
  void _forgotPassword() {
    Navigator.pushNamed(context, '/forgotPassword'); // make sure route exists
  }

  // === Navigate to Signup ===
  void _goToSignup() {
    Navigator.pushNamed(context, '/signup'); // make sure route exists
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Email field ===
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 12),

              // === Password field ===
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) => value == null || value.length < 8
                    ? "Enter valid password"
                    : null,
              ),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _signin,
                          child: const Text("Sign In"),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _signinWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text("Sign In with Google"),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _signinWithPhone,
                          icon: const Icon(Icons.phone_android),
                          label: const Text("Sign In with Phone OTP"),
                        ),
                      ],
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
    );
  }
}
