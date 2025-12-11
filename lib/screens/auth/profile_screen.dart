import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
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

    firstName.text = doc["firstName"] ?? "";
    lastName.text = doc["lastName"] ?? "";
    email.text = doc["email"] ?? user!.email ?? "";
    budget.text = doc["budget"] ?? "";
    preferredCity.text = doc["preferredCity"] ?? "";
    selectedState = doc["state"] ?? "CA";
    selectedPropertyType = doc["propertyType"] ?? "House";
    profileImageUrl = doc["profileImage"] ?? "";

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

    String freshUrl = await ref.getDownloadURL();
    freshUrl = "$freshUrl?v=${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"profileImage": freshUrl});

    imageCache.clear();
    imageCache.clearLiveImages();

    setState(() {
      profileImageUrl = freshUrl;
    });
  }

  Future<void> deleteAccount() async {
    bool confirmDelete = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              confirmDelete = true;
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!confirmDelete) return;

    await FirebaseFirestore.instance.collection("users").doc(user!.uid).delete();
    await user!.delete();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget modernField(TextEditingController controller, String label) {
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

  Widget dropdownField(String label, String value, List<String> items,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField(
        value: value,
        items:
            items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => onChanged(v.toString()),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: pickProfileImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[300],
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 55,
                          color: isDark ? Colors.white : Colors.black,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Personal Info"),
                  modernField(firstName, "First Name"),
                  modernField(lastName, "Last Name"),
                  Text("Email"),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(top: 6, bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    child: Text(
                      user?.email ?? "",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  sectionTitle("Preferences"),
                  modernField(budget, "Budget"),
                  modernField(preferredCity, "Preferred City"),
                  dropdownField("State", selectedState, states,
                      (v) => setState(() => selectedState = v)),
                  dropdownField("Property Type", selectedPropertyType,
                      propertyTypes, (v) => setState(() => selectedPropertyType = v)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        loading ? "Saving..." : "Save Profile",
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (_) =>
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
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
              child: const Text("Logout",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: deleteAccount,
              child: const Text("Delete Account",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}