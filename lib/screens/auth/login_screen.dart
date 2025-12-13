import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../widgets/bottom_nav_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  bool loading = false;

  Future<void> loginUser() async {
    setState(() => loading = true);

    try {
      await auth.login(
        email.text.trim(),
        password.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNavScaffold(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // LOGO + BRAND
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? theme.colorScheme.surface
                      : theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "PropertyPulse",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Smarter home discovery, tailored to you",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),

              const SizedBox(height: 48),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Welcome back",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sign in to continue",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              CustomTextField(
                controller: email,
                hint: "Email",
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: password,
                hint: "Password",
                obscure: true,
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text("Forgot password?"),
                ),
              ),

              const SizedBox(height: 20),

              CustomButton(
                text: loading ? "Signing in..." : "Login",
                onTap: loading ? null : loginUser,
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New to PropertyPulse?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text("Create an account"),
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