import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool isLoading = false;
  String errorText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1D3557)),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: Color(0xFF1D3557), fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Enter your email and we'll send a link to reset your password.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            CustomTextField(controller: email, hint: "Email"),
            const SizedBox(height: 12),

            Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),

            CustomButton(
              text: isLoading ? "Sending..." : "Send Reset Link",
              onTap: isLoading
                  ? null
                  : () async {
                      setState(() {
                        errorText = "";
                        isLoading = true;
                      });

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email.text.trim());

                        if (!mounted) return;
                        setState(() => isLoading = false);

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Success"),
                            content: const Text(
                                "Password reset link sent. Please check your inbox."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                          errorText = e.toString();
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}