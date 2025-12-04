import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyService service = PropertyService();

  List<Property> listings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadListings();
  }

  Future<void> loadListings() async {
    final data = await service.fetchListings();

    if (!mounted) return; // prevent setState error

    setState(() {
      listings = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommended Properties"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : listings.isEmpty
              ? const Center(child: Text("No listings found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: listings.length,
                  itemBuilder: (context, i) {
                    final property = listings[i];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PropertyDetailScreen(property: property),
                          ),
                        );
                      },
                      child: PropertyCard(property: property),
                    );
                  },
                ),
    );
  }
}


// Property Card Widget

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.08),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              property.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(height: 180, child: Center(child: Text("No Image"))),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address
                Text(
                  property.address,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                // Location
                Text(
                  "${property.city}, ${property.state}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 8),

                // Price
                Text(
                  "\$${property.price}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Beds Bath Sqft
                Text(
                  "${property.beds} beds • ${property.baths} baths • ${property.sqft} sqft",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}