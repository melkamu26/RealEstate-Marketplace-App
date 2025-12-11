import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/bottom_nav_scaffold.dart';

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
  final budget = TextEditingController();
  final preferredCity = TextEditingController();

  String selectedState = "CA";
  String selectedPropertyType = "House";

  bool loading = false;
  final auth = AuthService();

  final List<String> states = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
    "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
    "VA","WA","WV","WI","WY"
  ];

final List<String> propertyTypes = [
  "House",
  "Apartment",
  "Townhouse",
  "Multi-Family",
  "Land / Lot"
];

  Future<void> signupUser() async {
    setState(() => loading = true);

    try {
      User? user = await auth.signup(
        email.text.trim(),
        password.text.trim(),
      );

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "firstName": firstName.text.trim(),
          "lastName": lastName.text.trim(),
          "email": email.text.trim(),
          "budget": budget.text.trim(),
          "preferredCity": preferredCity.text.trim(),
          "state": selectedState,
          "propertyType": selectedPropertyType,
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavScaffold()),
        );
      }
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
        title: const Text("Sign Up"),
        centerTitle: true,
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

            CustomTextField(controller: budget, hint: "Budget"),
            const SizedBox(height: 16),

            CustomTextField(controller: preferredCity, hint: "Preferred City"),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedState,
              items:
                  states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => selectedState = v!),
              decoration: const InputDecoration(labelText: "State"),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedPropertyType,
              items: propertyTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => selectedPropertyType = v!),
              decoration: const InputDecoration(labelText: "Property Type"),
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: loading ? "Creating..." : "Create Account",
              onTap: loading ? null : signupUser,
            ),
          ],
        ),
      ),
    );
  }
}