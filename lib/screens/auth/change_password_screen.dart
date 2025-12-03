import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  bool isLoading = false;
  String errorText = "";

  Future<void> _changePassword() async {
    setState(() {
      isLoading = true;
      errorText = "";
    });

    if (newPassword.text != confirmPassword.text) {
      setState(() {
        isLoading = false;
        errorText = "New passwords do not match.";
      });
      return;
    }

    try {
      User user = FirebaseAuth.instance.currentUser!;

      // Reauthenticate
      AuthCredential cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword.text.trim());

      if (!mounted) return;

      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Password updated successfully."),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1D3557)),
        title: const Text(
          "Change Password",
          style: TextStyle(color: Color(0xFF1D3557), fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(controller: oldPassword, hint: "Old Password", obscure: true),
            const SizedBox(height: 16),

            CustomTextField(controller: newPassword, hint: "New Password", obscure: true),
            const SizedBox(height: 16),

            CustomTextField(controller: confirmPassword, hint: "Confirm New Password", obscure: true),

            const SizedBox(height: 12),
            Text(errorText, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            CustomButton(
              text: isLoading ? "Saving..." : "Change Password",
              onTap: isLoading ? null : _changePassword,
            ),
          ],
        ),
      ),
    );
  }
}