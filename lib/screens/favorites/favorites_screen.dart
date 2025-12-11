import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final service = PropertyService();

  List<Property> properties = [];
  Set<String> compareList = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (service.user == null) {
      setState(() => loading = false);
      return;
    }

    // Load favorite properties
    final snap = await service.favRef.get();
    properties = snap.docs.map((d) => Property.fromMap(d.data())).toList();

    // Load compare list
    compareList = await service.getCompareList();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (service.user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to see your favorites")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? const Center(child: Text("No favorites yet"))
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, i) {
                    final p = properties[i];

                    return PropertyCard(
                      property: p,

                      // FAVORITE toggle
                      isFavorite: true,
                      onFavoriteToggle: () async {
                        await service.removeFavorite(p.propertyId);
                        properties.removeAt(i);
                        setState(() {});
                      },

                      // COMPARE toggle
                      isCompared: compareList.contains(p.propertyId),
                      onCompareToggle: () async {
                        final isSelected =
                            compareList.contains(p.propertyId);

                        // Remove from compare
                        if (isSelected) {
                          await service.removeFromCompare(p.propertyId);
                          compareList.remove(p.propertyId);
                        } else {
                          // Max 3 compare limit
                          if (compareList.length >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "You can compare up to 3 properties"),
                              ),
                            );
                            return;
                          }

                          await service.addToCompare(p);
                          compareList.add(p.propertyId);
                        }

                        setState(() {});
                      },

                      // Tap to open details
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