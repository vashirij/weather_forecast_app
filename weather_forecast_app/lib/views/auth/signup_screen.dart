import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final _authController = AuthController();

  bool _isLoading = false;

  // === Email/Password/Phone Signup ===
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        User user = await _authController.signup(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _phoneController.text.trim(),
        );
        Helpers.showSnackBar(context, "Signup successful: ${user.email}");
      } catch (e) {
        Helpers.showSnackBar(context, "Signup failed: $e", isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // === Google Signup ===
  void _signupWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      User user = await _authController.signupWithGoogle();
      Helpers.showSnackBar(context, "Google signup successful: ${user.email}");
    } catch (e) {
      Helpers.showSnackBar(context, "Google signup failed: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
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
                    Validators.isValidEmail(value ?? "") ? null : "Enter a valid email",
              ),
              const SizedBox(height: 12),

              // === Password field ===
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) =>
                    Validators.isValidPassword(value ?? "") ? null : "Weak password",
              ),
              const SizedBox(height: 12),

              // === Phone/OTP field ===
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone / OTP"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter phone/OTP" : null,
              ),
              const SizedBox(height: 20),

              // === Signup Button ===
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text("Signup"),
                    ),
              const SizedBox(height: 10),

              // === Google Signup Button ===
              OutlinedButton.icon(
                onPressed: _signupWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text("Signup with Google"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
