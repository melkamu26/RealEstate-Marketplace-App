import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';

import '../tour/buyer_tour_requests_screen.dart';
import '../tour/seller_tour_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final budget = TextEditingController();
  final preferredCity = TextEditingController();

  String selectedState = "CA";
  String selectedPropertyType = "House";
  String profileImageUrl = "";

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
    "House","Apartment","Townhouse","Multi-Family","Land / Lot"
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

    final data = doc.data()!;

    firstName.text = data["firstName"] ?? "";
    lastName.text = data["lastName"] ?? "";
    budget.text = data["budget"] ?? "";
    preferredCity.text = data["preferredCity"] ?? "";
    selectedState = data["state"] ?? "CA";
    selectedPropertyType = data["propertyType"] ?? "House";
    profileImageUrl = data["profileImage"] ?? "";

    setState(() {});
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
      "profileImage": profileImageUrl,
    });

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final ref = FirebaseStorage.instance.ref("profile_images/${user!.uid}.jpg");

    await ref.putFile(file);

    String url = await ref.getDownloadURL();
    url = "$url?v=${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"profileImage": url});

    imageCache.clear();
    imageCache.clearLiveImages();

    setState(() => profileImageUrl = url);
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickProfileImage,
              child: CircleAvatar(
                radius: 56,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                backgroundImage:
                    profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                child: profileImageUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 56,
                        color: isDark ? Colors.white : Colors.black,
                      )
                    : null,
              ),
            ),

            sectionTitle("Personal Info"),
            field(firstName, "First Name"),
            field(lastName, "Last Name"),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: Text(
                user?.email ?? "",
                style: const TextStyle(fontSize: 16),
              ),
            ),

            sectionTitle("Preferences"),
            field(budget, "Budget"),
            field(preferredCity, "Preferred City"),

            DropdownButtonFormField(
              value: selectedState,
              items: states
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedState = v.toString()),
              decoration: const InputDecoration(labelText: "State"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: selectedPropertyType,
              items: propertyTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => selectedPropertyType = v.toString()),
              decoration: const InputDecoration(labelText: "Property Type"),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                child: Text(loading ? "Saving..." : "Save Profile"),
              ),
            ),

            sectionTitle("Buyer"),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text("My Tour Requests"),
              subtitle: const Text("View your tours"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuyerTourRequestsScreen(),
                  ),
                );
              },
            ),

            sectionTitle("Seller"),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Tour Requests"),
              subtitle: const Text("Approve or decline tours"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerTourRequestsScreen(),
                  ),
                );
              },
            ),

            sectionTitle("Settings"),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
              child: const Text("Change Password"),
            ),

            TextButton(
              onPressed: () async {
                await auth.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}