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

  String selectedState = "GA";
  String selectedPropertyType = "House";

  bool loading = false;
  final auth = AuthService();

  final List<String> states = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
    "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
    "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
    "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
  ];

  final List<String> propertyTypes = [
    "House",
    "Apartment",
    "Townhouse",
    "Multi-Family",
    "Land / Lot"
  ];

  final Map<String, List<String>> famousCities = {
    "CA": ["Los Angeles", "San Diego", "San Jose", "San Francisco", "Sacramento"],
    "NY": ["New York", "Buffalo", "Rochester", "Albany", "Syracuse"],
    "TX": ["Houston", "Dallas", "Austin", "San Antonio", "Plano"],
    "FL": ["Miami", "Orlando", "Tampa", "Jacksonville", "Fort Lauderdale"],
    "GA": ["Atlanta", "Savannah", "Athens", "Augusta", "Marietta"],
    "IL": ["Chicago", "Naperville", "Aurora", "Evanston", "Schaumburg"],
    "AZ": ["Phoenix", "Scottsdale", "Tempe", "Mesa", "Chandler"],
    "WA": ["Seattle", "Bellevue", "Tacoma", "Redmond", "Everett"],
    "CO": ["Denver", "Boulder", "Aurora", "Fort Collins", "Lakewood"],
    "NC": ["Charlotte", "Raleigh", "Durham", "Cary", "Chapel Hill"],
    "NJ": ["Newark", "Jersey City", "Hoboken", "Edison", "Princeton"],
    "VA": ["Arlington", "Alexandria", "Fairfax", "Reston", "Tysons"],
    "MA": ["Boston", "Cambridge", "Somerville", "Newton", "Brookline"],
    "PA": ["Philadelphia", "Pittsburgh", "Allentown", "Bethlehem", "Lancaster"],
    "OH": ["Columbus", "Cleveland", "Cincinnati", "Dublin", "Westerville"],
  };

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final citySuggestions = famousCities[selectedState] ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.primary.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.home_work_rounded,
                        size: 52,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "PropertyPulse",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Create your account and find your next home",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              CustomTextField(controller: firstName, hint: "First Name"),
              const SizedBox(height: 16),

              CustomTextField(controller: lastName, hint: "Last Name"),
              const SizedBox(height: 16),

              CustomTextField(controller: email, hint: "Email"),
              const SizedBox(height: 16),

              CustomTextField(
                controller: password,
                hint: "Password",
                obscure: true,
              ),
              const SizedBox(height: 16),

              CustomTextField(controller: budget, hint: "Budget"),
              const SizedBox(height: 16),

              CustomTextField(
                controller: preferredCity,
                hint: "Preferred City",
              ),
              const SizedBox(height: 8),

              if (preferredCity.text.isEmpty && citySuggestions.isNotEmpty) ...[
                Text(
                  "Popular cities (or type any city)",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ],

              const SizedBox(height: 20),

              DropdownButtonFormField(
                value: selectedState,
                items: states
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedState = v!),
                decoration: const InputDecoration(labelText: "State"),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: selectedPropertyType,
                items: propertyTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedPropertyType = v!),
                decoration:
                    const InputDecoration(labelText: "Property Type"),
              ),

              const SizedBox(height: 28),

              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: loading ? "Creating account..." : "Create Account",
                    onTap: loading ? null : signupUser,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}