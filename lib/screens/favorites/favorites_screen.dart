import 'package:flutter/material.dart';

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

    final snap = await service.favRef.get();
    properties = snap.docs.map((d) => Property.fromMap(d.data())).toList();
    compareList = await service.getCompareList();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (service.user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please sign in to see your favorites"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Favorites",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 1,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())

          : properties.isEmpty
              ? _emptyState(isDark)

              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: properties.length,
                  itemBuilder: (context, i) {
                    final p = properties[i];

                    return PropertyCard(
                      property: p,

                      /// FAVORITE
                      isFavorite: true,
                      onFavoriteToggle: () async {
                        await service.removeFavorite(p.propertyId);
                        properties.removeAt(i);
                        setState(() {});
                      },

                      /// COMPARE
                      isCompared: compareList.contains(p.propertyId),
                      onCompareToggle: () async {
                        final selected =
                            compareList.contains(p.propertyId);

                        if (selected) {
                          await service.removeFromCompare(p.propertyId);
                          compareList.remove(p.propertyId);
                        } else {
                          if (compareList.length >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "You can compare up to 3 properties",
                                ),
                              ),
                            );
                            return;
                          }

                          await service.addToCompare(p);
                          compareList.add(p.propertyId);
                        }

                        setState(() {});
                      },

                      /// OPEN DETAILS
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PropertyDetailScreen(property: p),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  /// EMPTY STATE UI
  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 90,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              "No Favorites Yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Save homes you love and\nfind them here anytime.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}