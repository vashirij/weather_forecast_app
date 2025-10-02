import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import '../../utils/validators.dart';
import '../../utils/helpers.dart';

const Color kPrimaryColor = Color(0xFF0A3D62);
const Color kSurfaceLight = Color(0xFFF4F8FF);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _authController = AuthController();

  bool _isLoading = false;

  // === Email/Password/Phone Signup ===
  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Validate passwords match
        if (_passwordController.text.trim() !=
            _confirmPasswordController.text.trim()) {
          Helpers.showSnackBar(
            context,
            "Passwords do not match",
            isError: true,
          );
          return;
        }

        User user = await _authController.signup(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _phoneController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
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
  // Google signup removed; only email/password/phone signup supported.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceLight,
      appBar: AppBar(
        title: const Text("Signup", style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical -
                        kToolbarHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixIconColor: kPrimaryColor,
                          ),
                          elevatedButtonTheme: ElevatedButtonThemeData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                            ),
                          ),
                        ),
                        child: Card(
                          color: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 10),
                                  // === First name ===
                                  TextFormField(
                                    controller: _firstNameController,
                                    decoration: const InputDecoration(
                                      labelText: "First Name",
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? "Enter first name"
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // === Surname / Last Name ===
                                  TextFormField(
                                    controller: _lastNameController,
                                    decoration: const InputDecoration(
                                      labelText: "Surname",
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? "Enter surname"
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // === Email field ===
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: "Email",
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    validator: (value) =>
                                        Validators.isValidEmail(value ?? "")
                                        ? null
                                        : "Enter a valid email",
                                  ),
                                  const SizedBox(height: 12),

                                  // === Phone field ===
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: "Phone",
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? "Enter phone"
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  // === Password field ===
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: "Password",
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    validator: (value) =>
                                        Validators.isValidPassword(value ?? "")
                                        ? null
                                        : "Weak password",
                                  ),
                                  const SizedBox(height: 12),

                                  // === Confirm Password ===
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: "Confirm Password",
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return "Confirm password";
                                      if (value.trim() !=
                                          _passwordController.text.trim()) {
                                        return "Passwords do not match";
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // === Signup Button ===
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _signup,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text("Signup"),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Already have an account?"),
                                      TextButton(
                                        onPressed: () {
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          } else {
                                            Navigator.pushNamed(
                                              context,
                                              '/signin',
                                            );
                                          }
                                        },
                                        child: const Text("Sign In"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Loading overlay sits on top of everything in the Stack
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ], // Stack children
          ), // Stack
        ), // GestureDetector
      ), // SafeArea
    );
  }
}
