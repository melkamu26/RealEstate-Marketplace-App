import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final auth = AuthService();

  String errorText = "";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D3557)),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Color(0xFF1D3557), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(controller: firstName, hint: "First Name"),
            const SizedBox(height: 16),

            CustomTextField(controller: lastName, hint: "Last Name"),
            const SizedBox(height: 16),

            CustomTextField(controller: email, hint: "Email"),
            const SizedBox(height: 16),

            CustomTextField(controller: password, hint: "Password", obscure: true),
            const SizedBox(height: 16),

            CustomTextField(controller: confirmPassword, hint: "Confirm Password", obscure: true),
            const SizedBox(height: 12),

            Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),

            CustomButton(
              text: isLoading ? "Creating..." : "Create Account",
              onTap: isLoading
                  ? null
                  : () async {
                      if (password.text.trim() != confirmPassword.text.trim()) {
                        setState(() => errorText = "Passwords do not match");
                        return;
                      }

                      setState(() {
                        errorText = "";
                        isLoading = true;
                      });

                      try {
                        // Step 1: Create Auth User
                        final user = await auth.signup(
                          email.text.trim(),
                          password.text.trim(),
                        );

                        // Step 2: Create Firestore User DOC
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user!.uid)
                            .set({
                          "firstName": firstName.text.trim(),
                          "lastName": lastName.text.trim(),
                          "email": email.text.trim(),
                          "password": password.text.trim(), // optional
                          "priceRange": "",
                          "preferredCity": "",
                          "propertyType": "",
                          "createdAt": DateTime.now(),
                        });

                        if (!mounted) return;
                        setState(() => isLoading = false);

                        // Success popup
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Success"),
                            content: const Text("Account created! Please log in."),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text("OK"),
                              )
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
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