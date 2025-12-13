import 'package:flutter/material.dart';

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

  int minPrice = 0;
  int maxPrice = 0;

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

    final snap = await service.compareRef.get();
    items = snap.docs.map((d) => Property.fromMap(d.data())).toList();

    favorites = await service.getFavorites();

    if (items.isNotEmpty) {
      final prices = items.map((p) => p.priceInt).toList();
      minPrice = prices.reduce((a, b) => a < b ? a : b);
      maxPrice = prices.reduce((a, b) => a > b ? a : b);
    }

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

  Widget _priceBadge(Property p, ThemeData theme) {
    if (p.priceInt == maxPrice && items.length > 1) {
      return _badge("Most Expensive", Colors.red.shade600);
    }
    if (p.priceInt == minPrice && items.length > 1) {
      return _badge("Best Value", Colors.green.shade600);
    }
    return const SizedBox.shrink();
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (service.user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please sign in to compare properties"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Compare",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
              ? _emptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _priceBadge(p, theme),

                        PropertyCard(
                          property: p,

                          isFavorite: favorites.contains(p.propertyId),
                          onFavoriteToggle: () async {
                            if (favorites.contains(p.propertyId)) {
                              await service.removeFavorite(p.propertyId);
                              favorites.remove(p.propertyId);
                            } else {
                              await service.addFavorite(p);
                              favorites.add(p.propertyId);
                            }
                            setState(() {});
                          },

                          isCompared: true,
                          onCompareToggle: () async {
                            await service.removeFromCompare(p.propertyId);
                            items.removeAt(i);
                            _loadData();
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

                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 80,
              color: theme.hintColor,
            ),
            const SizedBox(height: 20),
            const Text(
              "No properties to compare",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add up to 3 homes from Home or Search\nand compare prices, size, and value.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}