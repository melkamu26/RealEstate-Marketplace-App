import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  String errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'PropertyPulse',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3557),
                ),
              ),

              const SizedBox(height: 40),

              CustomTextField(controller: email, hint: "Email"),
              const SizedBox(height: 20),

              CustomTextField(controller: password, hint: "Password", obscure: true),
              const SizedBox(height: 10),

              Text(errorText, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),

              CustomButton(
                text: "Login",
                onTap: () async {
                  try {
                    await auth.login(email.text.trim(), password.text.trim());

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
                      (route) => false,
                    );
                  } catch (e) {
                    setState(() => errorText = e.toString());
                  }
                },
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color(0xFF1D3557),
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Color(0xFF1D3557),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}