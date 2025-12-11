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
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Recommended Properties"),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 1,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : listings.isEmpty
              ? Center(
                  child: Text(
                    "No listings found",
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge!.color,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listings.length,
                  itemBuilder: (_, i) {
                    final p = listings[i];

                    return PropertyCard(
                      property: p,

                      isFavorite: favorites.contains(p.propertyId),
                      onFavoriteToggle: () async {
                        final isFav = favorites.contains(p.propertyId);
                        if (isFav) {
                          await service.removeFavorite(p.propertyId);
                          favorites.remove(p.propertyId);
                        } else {
                          await service.addFavorite(p);
                          favorites.add(p.propertyId);
                        }
                        setState(() {});
                      },

                      isCompared: compared.contains(p.propertyId),
                      onCompareToggle: () async {
                        final isInList = compared.contains(p.propertyId);

                        if (isInList) {
                          await service.removeFromCompare(p.propertyId);
                          compared.remove(p.propertyId);
                        } else {
                          if (compared.length >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("You can compare max 3 properties"),
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
                            builder: (_) => PropertyDetailScreen(property: p),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}