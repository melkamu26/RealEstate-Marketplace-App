import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/property_card.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyService service = PropertyService();

  List<Property> listings = [];
  Set<String> favorites = {};
  Set<String> compared = {};
  bool loading = true;

  String firstName = "";
  String userCity = "";
  String userBudget = "";
  String userType = "";
  String userState = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFavorites();
    _loadCompare();
  }

  Future<void> _loadFavorites() async {
    favorites = await service.getFavorites();
    setState(() {});
  }

  Future<void> _loadCompare() async {
    compared = await service.getCompareList();
    setState(() {});
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    firstName = (data["firstName"] ?? "").toString().trim();
    userCity = data["preferredCity"] ?? "";
    userBudget = data["budget"] ?? "";
    userType = data["propertyType"] ?? "";
    userState = data["state"] ?? "";

    _loadListings();
  }

  Future<void> _loadListings() async {
    final maxPrice = userBudget.isEmpty ? "999999999" : userBudget;

    final data = await service.searchProperties(
      city: userCity,
      state: userState,
      maxPrice: maxPrice,
      propertyType: userType,
    );

    setState(() {
      listings = data;
      loading = false;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final name = firstName.isNotEmpty ? firstName : "";

    if (hour < 12) return "Good morning, $name";
    if (hour < 17) return "Good afternoon, $name";
    return "Good evening, $name";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      ///  APP BAR (CONSISTENT WITH OTHER TABS)
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "PropertyPulse",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///  CLEAN HEADER (NO PARAGRAPHS)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Recommended homes for you",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                ///  LISTINGS
                Expanded(
                  child: listings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 72,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No recommendations yet",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Update your preferences to see homes here.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: listings.length,
                          itemBuilder: (_, i) {
                            final p = listings[i];

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 18),
                              child: PropertyCard(
                                property: p,
                                isFavorite:
                                    favorites.contains(p.propertyId),
                                isCompared:
                                    compared.contains(p.propertyId),

                                onFavoriteToggle: () async {
                                  if (favorites
                                      .contains(p.propertyId)) {
                                    await service.removeFavorite(
                                        p.propertyId);
                                    favorites.remove(p.propertyId);
                                  } else {
                                    await service.addFavorite(p);
                                    favorites.add(p.propertyId);
                                  }
                                  setState(() {});
                                },

                                onCompareToggle: () async {
                                  if (compared
                                      .contains(p.propertyId)) {
                                    await service.removeFromCompare(
                                        p.propertyId);
                                    compared.remove(p.propertyId);
                                  } else {
                                    if (compared.length >= 3) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "You can compare up to 3 properties"),
                                        ),
                                      );
                                      return;
                                    }
                                    await service.addToCompare(p);
                                    compared.add(p.propertyId);
                                  }
                                  setState(() {});
                                },

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PropertyDetailScreen(
                                              property: p),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}