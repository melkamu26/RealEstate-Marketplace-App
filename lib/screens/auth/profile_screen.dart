import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import 'change_password_screen.dart';
import '../auth/login_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final budget = TextEditingController();
  final preferredCity = TextEditingController();

  String selectedState = "CA";
  String selectedPropertyType = "House";

  bool loading = false;

  final user = FirebaseAuth.instance.currentUser;
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

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

    if (!doc.exists) return;

    setState(() {
      firstName.text = doc["firstName"] ?? "";
      lastName.text = doc["lastName"] ?? "";
      email.text = doc["email"] ?? "";
      budget.text = doc["budget"] ?? "";
      preferredCity.text = doc["preferredCity"] ?? "";
      selectedState = doc["state"] ?? "CA";
      selectedPropertyType = doc["propertyType"] ?? "House";
    });
  }

  Future<void> saveProfile() async {
    if (user == null) return;

    setState(() => loading = true);

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      "firstName": firstName.text.trim(),
      "lastName": lastName.text.trim(),
      "budget": budget.text.trim(),
      "preferredCity": preferredCity.text.trim(),
      "state": selectedState,
      "propertyType": selectedPropertyType,
    });

    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;

              // CLEAR NAVIGATION STACK → Go to LoginScreen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(controller: firstName, hint: "First Name"),
            const SizedBox(height: 16),

            CustomTextField(controller: lastName, hint: "Last Name"),
            const SizedBox(height: 16),

            // READ ONLY EMAIL
            TextField(
              controller: email,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(controller: budget, hint: "Budget"),
            const SizedBox(height: 16),

            CustomTextField(controller: preferredCity, hint: "Preferred City"),
            const SizedBox(height: 16),

            // STATE DROPDOWN
            DropdownButtonFormField(
              value: selectedState,
              items: states
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() => selectedState = value!),
              decoration: const InputDecoration(
                labelText: "State",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // PROPERTY TYPE DROPDOWN
            DropdownButtonFormField(
              value: selectedPropertyType,
              items: propertyTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) => setState(() => selectedPropertyType = value!),
              decoration: const InputDecoration(
                labelText: "Property Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: loading ? "Saving..." : "Save Profile",
              onTap: loading ? null : saveProfile,
            ),

            const SizedBox(height: 24),

            TextButton(
              child: const Text(
                "Change Password",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}