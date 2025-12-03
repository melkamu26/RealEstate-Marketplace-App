import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final priceRange = TextEditingController();
  final preferredCity = TextEditingController();
  final propertyType = TextEditingController();

  final auth = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  String errorText = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();

    if (doc.exists) {
      setState(() {
        firstName.text = doc["firstName"] ?? "";
        lastName.text = doc["lastName"] ?? "";
        priceRange.text = doc["priceRange"] ?? "";
        preferredCity.text = doc["preferredCity"] ?? "";
        propertyType.text = doc["propertyType"] ?? "";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    setState(() {
      isLoading = true;
      errorText = "";
    });

    try {
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "priceRange": priceRange.text.trim(),
        "preferredCity": preferredCity.text.trim(),
        "propertyType": propertyType.text.trim(),
      });

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
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
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!mounted) return;
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(controller: firstName, hint: "First Name"),
            const SizedBox(height: 10),

            CustomTextField(controller: lastName, hint: "Last Name"),
            const SizedBox(height: 10),

            CustomTextField(controller: priceRange, hint: "Price Range (e.g. 200k - 400k)"),
            const SizedBox(height: 10),

            CustomTextField(controller: preferredCity, hint: "Preferred City"),
            const SizedBox(height: 10),

            CustomTextField(controller: propertyType, hint: "Property Type (House, Condo, etc.)"),
            const SizedBox(height: 10),

            Text(errorText, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),

            CustomButton(
              text: isLoading ? "Saving..." : "Save Profile",
              onTap: isLoading ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}