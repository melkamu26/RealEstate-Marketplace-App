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
  String errorText = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(controller: firstName, hint: "First Name"),
            const SizedBox(height: 10),

            CustomTextField(controller: lastName, hint: "Last Name"),
            const SizedBox(height: 10),

            CustomTextField(controller: email, hint: "Email"),
            const SizedBox(height: 10),

            CustomTextField(controller: password, hint: "Password", obscure: true),
            const SizedBox(height: 10),

            CustomTextField(controller: confirmPassword, hint: "Confirm Password", obscure: true),
            const SizedBox(height: 10),

            Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),

            CustomButton(
              text: isLoading ? "Creating..." : "Sign Up",
              onTap: () async {
                if (isLoading) return;

                if (password.text != confirmPassword.text) {
                  setState(() => errorText = "Passwords do not match");
                  return;
                }

                setState(() => isLoading = true);

                try {
                  // Create user
                  final user = await auth.signup(email.text, password.text);

                  // Store profile in Firestore
                  await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
                    "firstName": firstName.text,
                    "lastName": lastName.text,
                    "email": email.text,
                    "createdAt": DateTime.now(),
                  });

                  setState(() {
                    errorText = "";
                    isLoading = false;
                  });

                  // Success popup
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Success"),
                      content: const Text("Account created! Please log in."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context); // return to login
                          },
                          child: const Text("OK"),
                        )
                      ],
                    ),
                  );

                } catch (e) {
                  setState(() {
                    errorText = e.toString();
                    isLoading = false;
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
