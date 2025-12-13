import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/theme_provider.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';

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
  bool loading = false;

  final user = FirebaseAuth.instance.currentUser;
  final auth = AuthService();

  final states = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
    "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
    "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
  ];

  final propertyTypes = [
    "House","Apartment","Townhouse","Multi-Family","Land / Lot"
  ];

  final Map<String, List<String>> famousCities = {
    "CA": ["Los Angeles", "San Diego", "San Jose", "San Francisco"],
    "NY": ["New York", "Buffalo", "Rochester", "Albany"],
    "TX": ["Houston", "Dallas", "Austin", "San Antonio"],
    "FL": ["Miami", "Orlando", "Tampa", "Jacksonville"],
    "GA": ["Atlanta", "Savannah", "Athens", "Augusta"],
    "IL": ["Chicago", "Naperville", "Aurora"],
    "AZ": ["Phoenix", "Scottsdale", "Tempe"],
    "WA": ["Seattle", "Bellevue", "Tacoma"],
    "CO": ["Denver", "Boulder", "Aurora"],
    "NC": ["Charlotte", "Raleigh", "Durham"],
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

    setState(() {});
  }

  Future<void> _saveProfile() async {
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

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "This will permanently delete your account.\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .delete();

      await user!.delete();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please re-login before deleting your account."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final citySuggestions = famousCities[selectedState] ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "${firstName.text} ${lastName.text}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "",
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle("Preferences"),
            _card(
              child: Column(
                children: [
                  _field(firstName, "First Name"),
                  _field(lastName, "Last Name"),
                  _field(budget, "Budget"),
                  _field(preferredCity, "Preferred City"),

                  if (preferredCity.text.isEmpty && citySuggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        children: citySuggestions.map((city) {
                          return ActionChip(
                            label: Text(city),
                            onPressed: () {
                              preferredCity.text = city;
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  DropdownButtonFormField(
                    value: selectedState,
                    items: states
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedState = v!),
                    decoration: const InputDecoration(labelText: "State"),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField(
                    value: selectedPropertyType,
                    items: propertyTypes
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedPropertyType = v!),
                    decoration:
                        const InputDecoration(labelText: "Property Type"),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _saveProfile,
                      child: Text(loading ? "Saving..." : "Save Changes"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle("Settings"),
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text("Change Password"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionTitle("Account"),
            _card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("Logout"),
                    onTap: () async {
                      await auth.logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      "Delete Account",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}