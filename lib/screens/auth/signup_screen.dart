import 'package:flutter/material.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  String errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(controller: email, hint: 'Email'),
            SizedBox(height: 10),
            CustomTextField(controller: password, hint: 'Password', obscure: true),
            SizedBox(height: 10),

            Text(errorText, style: TextStyle(color: Colors.red)),

            SizedBox(height: 20),
            CustomButton(
              text: 'Sign Up',
              onTap: () async {
                try {
                  await auth.signup(email.text, password.text);
                  Navigator.pop(context);
                } catch (e) {
                  setState(() => errorText = e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
