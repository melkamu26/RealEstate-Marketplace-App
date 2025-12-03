import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav_scaffold.dart';
import 'signup_screen.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('PropertyPulse',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            CustomTextField(controller: email, hint: 'Email'),
            SizedBox(height: 10),
            CustomTextField(controller: password, hint: 'Password', obscure: true),
            SizedBox(height: 10),

            Text(errorText, style: TextStyle(color: Colors.red)),

            SizedBox(height: 20),
            CustomButton(
              text: 'Login',
              onTap: () async {
                try {
                  await auth.login(email.text, password.text);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
                  );
                } catch (e) {
                  setState(() => errorText = e.toString());
                }
              },
            ),

            TextButton(
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()));
              },
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
