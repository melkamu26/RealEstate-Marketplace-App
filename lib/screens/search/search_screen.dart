import 'package:flutter/material.dart';
import '../../services/property_service.dart';
import '../../models/property.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final city = TextEditingController();
  final maxPrice = TextEditingController();

  String selectedState = "GA";
  String selectedType = "House";

  bool loading = false;
  List<Property> results = [];

  Set<String> favorites = {};
  Set<String> compared = {}; // 🔥 Track compared items (Firestore)

  final service = PropertyService();

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

  @override
  void initState() {
    super.initState();
    loadFavorites();
    loadCompare(); // 🔥 Load compare list on open
  }

  // ❤️ Load favorites
  Future<void> loadFavorites() async {
    favorites = (await service.getFavorites()).toSet();
    setState(() {});
  }

  // 🔥 Load compared properties from Firestore
  Future<void> loadCompare() async {
    compared = await service.getCompareList();
    setState(() {});
  }

  // RUN SEARCH
  Future<void> runSearch() async {
    setState(() => loading = true);

    String price =
        maxPrice.text.trim().isEmpty ? "999999999" : maxPrice.text.trim();

    results = await service.searchProperties(
      city: city.text.trim(),
      state: selectedState,
      maxPrice: price,
      propertyType: selectedType,
    );

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Properties")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: city, decoration: const InputDecoration(hintText: "City")),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedState,
              items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => selectedState = v!),
              decoration: const InputDecoration(labelText: "State"),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: maxPrice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Max Price"),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedType,
              items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => selectedType = v!),
              decoration: const InputDecoration(labelText: "Property Type"),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: runSearch,
              child: const Text("Search"),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : Column(
                    children: results.map((p) {
                      return PropertyCard(
                        property: p,

                        // ❤️ FAVORITE
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

                        // 🔥 COMPARISON CHECKBOX
                        isCompared: compared.contains(p.propertyId),
                        onCompareToggle: () async {
                          final isChecked = compared.contains(p.propertyId);

                          if (isChecked) {
                            // REMOVE FROM FIRESTORE
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

                            // ADD TO FIRESTORE
                            await service.addToCompare(p);
                            compared.add(p.propertyId);
                          }

                          setState(() {});
                        },

                        // TAP CARD → DETAILS
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
                  )
          ],
        ),
      ),
    );
  }
}