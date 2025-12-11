import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final PropertyService service = PropertyService();

  List<Property> items = [];
  Set<String> favorites = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (service.user == null) {
      setState(() => loading = false);
      return;
    }

    // load compare properties
    final snap = await service.compareRef.get();
    items = snap.docs.map((d) => Property.fromMap(d.data())).toList();

    // load favorites so hearts work
    favorites = await service.getFavorites();

    setState(() => loading = false);
  }

  Future<void> _clearCompare() async {
    final snap = await service.compareRef.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    setState(() {
      items.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (service.user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please sign in to compare properties"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Compare Properties"),
        centerTitle: true,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear compare list",
              onPressed: _clearCompare,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text(
                    "No properties to compare.\nGo to Home or Search and tap 'Compare'.",
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];

                    return PropertyCard(
                      property: p,

                      // ❤️ FAVORITE SUPPORT
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

                      // 🔲 COMPARE – remove from compare list here
                      isCompared: true,
                      onCompareToggle: () async {
                        await service.removeFromCompare(p.propertyId);
                        items.removeAt(i);
                        setState(() {});
                      },

                      // TAP → DETAILS
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
}