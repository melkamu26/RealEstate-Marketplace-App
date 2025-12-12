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
      duration: const Duration(milliseconds: 350),
    );
    fadeAnimation =
        CurvedAnimation(parent: fadeController, curve: Curves.easeInOut);
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
            return _SearchQuery.fromMap(jsonDecode(s));
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

    await prefs.setStringList(
      "recent_searches_v2",
      recentSearches.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  Future<void> runSearch({bool saveQuery = true}) async {
    setState(() {
      loading = true;
      hasSearched = true;
    });

    final query = _SearchQuery(
      city: city.text.trim(),
      state: selectedState,
      type: selectedType,
      maxPrice:
          maxPrice.text.trim().isEmpty ? "999999999" : maxPrice.text.trim(),
    );

    if (saveQuery) await saveRecentSearch(query);

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
    final theme = Theme.of(context);
    final suggestedList = citySuggestions[selectedState] ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Search Properties",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              child: Column(
                children: [
                  TextField(
                    controller: city,
                    decoration: const InputDecoration(
                      hintText: "City (optional)",
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),

                  if (suggestedList.isNotEmpty && city.text.isEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
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
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedState = v!),
                    decoration:
                        const InputDecoration(labelText: "State"),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: maxPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Max Price (optional)",
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField(
                    value: selectedType,
                    items: types
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v!),
                    decoration:
                        const InputDecoration(labelText: "Property Type"),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading ? null : runSearch,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("Search"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: clearFilters,
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (recentSearches.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                "Recent Searches",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...recentSearches.map((q) {
                return Card(
                  child: ListTile(
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
                  ),
                );
              }),
            ],

            const SizedBox(height: 30),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMainContent(),
            ),
          ],
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(Icons.search, size: 90, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Start Searching",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Find homes, apartments, or land\nby location and budget.",
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
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text(
              "No properties found",
              style: TextStyle(fontSize: 18),
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
              isFav
                  ? await service.removeFavorite(p.propertyId)
                  : await service.addFavorite(p);
              setState(() {
                isFav
                    ? favorites.remove(p.propertyId)
                    : favorites.add(p.propertyId);
              });
            },
            isCompared: compared.contains(p.propertyId),
            onCompareToggle: () async {
              if (compared.contains(p.propertyId)) {
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

  Widget _sectionCard({required Widget child}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
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
        maxPrice == "999999999" ? "Any price" : "Under \$$maxPrice";
    return "$cityPart • $type • $pricePart";
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