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

  String userCity = "";
  String userBudget = "";
  String userType = "";
  String userState = "";

  @override
  void initState() {
    super.initState();
    loadUserPreferences();
    loadFavorites();
    loadCompare();
  }

  Future<void> loadFavorites() async {
    favorites = await service.getFavorites();
    setState(() {});
  }

  Future<void> loadCompare() async {
    compared = await service.getCompareList();
    setState(() {});
  }

  Future<void> loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    userCity = data["preferredCity"] ?? "";
    userBudget = data["budget"] ?? "";
    userType = data["propertyType"] ?? "";
    userState = data["state"] ?? "";

    loadListings();
  }

  Future<void> loadListings() async {
    List<Property> data;

    String price = userBudget.isEmpty ? "999999999" : userBudget;

    if (userCity.isNotEmpty ||
        userState.isNotEmpty ||
        userBudget.isNotEmpty ||
        userType.isNotEmpty) {
      data = await service.searchProperties(
        city: userCity,
        state: userState,
        maxPrice: price,
        propertyType: userType,
      );
    } else {
      data = await service.fetchListings();
    }

    setState(() {
      listings = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? Colors.grey.shade900 : const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Recommended Properties",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : listings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 70,
                          color: isDark
                              ? Colors.white38
                              : Colors.black38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No listings found",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Try updating your preferences",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: listings.length,
                  itemBuilder: (_, i) {
                    final p = listings[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black26
                                : Colors.black12,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: PropertyCard(
                        property: p,

                        isFavorite: favorites.contains(p.propertyId),
                        onFavoriteToggle: () async {
                          final isFav =
                              favorites.contains(p.propertyId);
                          if (isFav) {
                            await service
                                .removeFavorite(p.propertyId);
                            favorites.remove(p.propertyId);
                          } else {
                            await service.addFavorite(p);
                            favorites.add(p.propertyId);
                          }
                          setState(() {});
                        },

                        isCompared: compared.contains(p.propertyId),
                        onCompareToggle: () async {
                          final isInList =
                              compared.contains(p.propertyId);

                          if (isInList) {
                            await service
                                .removeFromCompare(p.propertyId);
                            compared.remove(p.propertyId);
                          } else {
                            if (compared.length >= 3) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "You can compare max 3 properties"),
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
                                  PropertyDetailScreen(property: p),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}