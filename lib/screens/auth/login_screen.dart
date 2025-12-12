import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
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
      await auth.login(email.text.trim(), password.text.trim());
      if (!mounted) return;

      // remove the broken "/home" navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(controller: email, hint: "Email"),
            const SizedBox(height: 16),
            CustomTextField(controller: password, hint: "Password", obscure: true),

            const SizedBox(height: 24),
            CustomButton(
              text: loading ? "Loading..." : "Login",
              onTap: loading ? null : loginUser,
            ),

            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text("Don't have an account? Signup"),
            )
          ],
        ),
      ),
    );
  }
}