import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/helpers.dart';
import 'forgot_password_screen.dart';

const Color kPrimaryColor = Color(0xFF0A3D62);
const Color kSurfaceLight = Color(0xFFF4F8FF);

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // phone sign-in removed; no phone controller required
  final _authController = AuthController();

  // toggle password visibility
  bool _obscurePassword = true;

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
        if (!mounted) return;
        final ctx = context;
        Helpers.showSnackBar(ctx, "Welcome back ${user.email}");
        Navigator.pushReplacementNamed(ctx, '/dailyForecast');
      } catch (e) {
        if (!mounted) return;
        final ctx = context;
        Helpers.showSnackBar(ctx, "Sign in failed: $e", isError: true);
      } finally {
        _setLoading(false);
      }
    }
  }

  // Google and Phone OTP sign-ins removed; only email/password supported here.

  void _forgotPassword() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
  );

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
      backgroundColor: kSurfaceLight,
      appBar: AppBar(
        title: const Text("Sign In", style: TextStyle(color: Colors.white)),
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
                                  // === Email field ===
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: "Email",
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),

                                  // === Password field ===
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  const SizedBox(height: 20),

                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _signin,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text("Sign In"),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

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
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // === Loading Overlay ===
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
