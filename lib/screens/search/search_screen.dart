import 'package:flutter/material.dart';
import '../../services/property_service.dart';
import '../../models/property.dart';
import '../home/property_detail_screen.dart';
import '../home/home_screen.dart'; // for PropertyCard widget

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final city = TextEditingController();
  final maxPrice = TextEditingController();

  String selectedState = "CA";
  String selectedPropertyType = "House";

  List<Property> results = [];
  bool loading = false;

  final PropertyService service = PropertyService();

  final List<String> states = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
    "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
    "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
    "VA","WA","WV","WI","WY"
  ];

  final List<String> propertyTypes = [
    "House",
    "Condo",
    "Apartment",
    "Multi-Family",
    "Townhouse",
    "Land / Lot"
  ];

  Future<void> search() async {
    setState(() => loading = true);

    results = await service.searchProperties(
      city: city.text.trim(),
      state: selectedState,
      maxPrice: maxPrice.text.trim(),
      propertyType: selectedPropertyType,
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
              onChanged: (value) => setState(() => selectedState = value!),
              decoration: const InputDecoration(labelText: "State"),
            ),
            const SizedBox(height: 16),

            TextField(controller: maxPrice, decoration: const InputDecoration(hintText: "Max Price")),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: selectedPropertyType,
              items: propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (value) => setState(() => selectedPropertyType = value!),
              decoration: const InputDecoration(labelText: "Property Type"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: search,
              child: const Text("Search"),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : Column(
                    children: results
                        .map((p) => GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PropertyDetailScreen(property: p),
                                  ),
                                );
                              },
                              child: PropertyCard(property: p),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}