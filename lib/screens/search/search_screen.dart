import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/property_service.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final city = TextEditingController();
  final maxPrice = TextEditingController();

  String selectedState = "GA";
  String selectedType = "House";

  bool loading = false;
  bool hasSearched = false;

  List<Property> results = [];
  List<_SearchQuery> recentSearches = [];

  Set<String> favorites = {};
  Set<String> compared = {};

  final service = PropertyService();

  late AnimationController fadeController;
  late Animation<double> fadeAnimation;

  final states = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
    "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
    "VA","WA","WV","WI","WY"
  ];

  final types = [
    "House",
    "Apartment",
    "Townhouse",
    "Multi-Family",
    "Land / Lot"
  ];

  final Map<String, List<String>> citySuggestions = {
    "GA": ["Atlanta", "Savannah", "Augusta", "Athens"],
    "CA": ["Los Angeles", "San Diego", "San Jose", "Sacramento"],
    "TX": ["Houston", "Dallas", "Austin", "San Antonio"],
    "FL": ["Miami", "Orlando", "Tampa", "Jacksonville"],
  };

  @override
  void initState() {
    super.initState();
    loadFavorites();
    loadCompare();
    loadRecentSearches();

    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    city.dispose();
    maxPrice.dispose();
    fadeController.dispose();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    favorites = (await service.getFavorites()).toSet();
    setState(() {});
  }

  Future<void> loadCompare() async {
    compared = await service.getCompareList();
    setState(() {});
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList("recent_searches_v2") ?? [];
    recentSearches = list
        .map((s) {
          try {
            final map = jsonDecode(s) as Map<String, dynamic>;
            return _SearchQuery.fromMap(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<_SearchQuery>()
        .toList();
    setState(() {});
  }

  Future<void> saveRecentSearch(_SearchQuery q) async {
    final prefs = await SharedPreferences.getInstance();

    recentSearches.removeWhere((e) => e.label == q.label);
    recentSearches.insert(0, q);

    if (recentSearches.length > 5) {
      recentSearches = recentSearches.take(5).toList();
    }

    final encoded = recentSearches
        .map((q) => jsonEncode(q.toMap()))
        .toList();

    await prefs.setStringList("recent_searches_v2", encoded);
  }

  // 🔍 MAIN SEARCH (city optional)
  Future<void> runSearch({bool saveQuery = true}) async {
    final cityText = city.text.trim();

    setState(() {
      loading = true;
      hasSearched = true;
    });

    final priceText =
        maxPrice.text.trim().isEmpty ? "999999999" : maxPrice.text.trim();

    final query = _SearchQuery(
      city: cityText,
      state: selectedState,
      type: selectedType,
      maxPrice: priceText,
    );

    if (saveQuery) {
      await saveRecentSearch(query);
    }

    results = await service.searchProperties(
      city: query.city,
      state: query.state,
      maxPrice: query.maxPrice,
      propertyType: query.type,
    );

    setState(() => loading = false);

    fadeController.forward(from: 0);
  }

  void clearFilters() {
    city.clear();
    maxPrice.clear();
    selectedState = "GA";
    selectedType = "House";
    results.clear();
    hasSearched = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final suggestedList = citySuggestions[selectedState] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Search Properties")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: city,
                decoration: const InputDecoration(
                  hintText: "City (optional)",
                ),
              ),
              if (suggestedList.isNotEmpty && city.text.isEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: suggestedList.map((c) {
                    return ActionChip(
                      label: Text(c),
                      onPressed: () {
                        city.text = c;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: selectedState,
                items: states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedState = v!),
                decoration: const InputDecoration(labelText: "State"),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: maxPrice,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Max Price (optional)",
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: selectedType,
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => selectedType = v!),
                decoration: const InputDecoration(labelText: "Property Type"),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : () => runSearch(),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Search"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: clearFilters,
                    child: const Text("Clear"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (recentSearches.isNotEmpty) ...[
                const Text(
                  "Recent Searches",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...recentSearches.map((q) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(q.label),
                    onTap: () {
                      city.text = q.city;
                      selectedState = q.state;
                      selectedType = q.type;
                      maxPrice.text =
                          q.maxPrice == "999999999" ? "" : q.maxPrice;

                      setState(() {});
                      runSearch(saveQuery: false);
                    },
                  );
                }),
                const Divider(),
              ],

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (!hasSearched) {
      return Center(
        key: const ValueKey("idle"),
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: const [
              Icon(Icons.search, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Start Searching",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Enter a city or choose a state\nto begin your search.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (results.isEmpty) {
      return FadeTransition(
        opacity: fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(
              children: const [
                Icon(Icons.search_off, size: 80, color: Colors.grey),
                SizedBox(height: 15),
                Text(
                  "No properties found",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Try adjusting your filters\nor searching another area.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        children: results.map((p) {
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
              final isChecked = compared.contains(p.propertyId);

              if (isChecked) {
                await service.removeFromCompare(p.propertyId);
                compared.remove(p.propertyId);
              } else {
                if (compared.length >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("You can compare up to 3 properties"),
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
        }).toList(),
      ),
    );
  }
}

class _SearchQuery {
  final String city;
  final String state;
  final String type;
  final String maxPrice;

  _SearchQuery({
    required this.city,
    required this.state,
    required this.type,
    required this.maxPrice,
  });

  String get label {
    final cityPart = city.isEmpty ? state : "$city, $state";
    final pricePart =
        maxPrice == "999999999" ? "Any price" : "under \$$maxPrice";
    return "$cityPart - $type $pricePart";
  }

  Map<String, dynamic> toMap() => {
        "city": city,
        "state": state,
        "type": type,
        "maxPrice": maxPrice,
      };

  factory _SearchQuery.fromMap(Map<String, dynamic> map) {
    return _SearchQuery(
      city: map["city"] ?? "",
      state: map["state"] ?? "",
      type: map["type"] ?? "",
      maxPrice: map["maxPrice"] ?? "999999999",
    );
  }
}