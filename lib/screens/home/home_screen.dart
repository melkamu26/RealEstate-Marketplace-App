import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/property_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PropertyService propertyService = PropertyService();
  List listings = [];
  bool loading = true;

  late final String googleApiKey;

  @override
  void initState() {
    super.initState();
    googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    loadListings();
  }

  Future<void> loadListings() async {
    try {
      final data = await propertyService.getListings();
      setState(() {
        listings = data;
        loading = false;
      });
    } catch (e) {
      print("Error loading listings: $e");
      setState(() => loading = false);
    }
  }

  String getStreetViewImage(dynamic listing) {
    final lat = listing["location"]?["address"]?["coordinate"]?["lat"];
    final lon = listing["location"]?["address"]?["coordinate"]?["lon"];

    if (lat == null || lon == null || googleApiKey.isEmpty) return "";

    return "https://maps.googleapis.com/maps/api/streetview"
        "?size=1280x720"
        "&location=$lat,$lon"
        "&fov=80"
        "&pitch=0"
        "&key=$googleApiKey";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Recommended Properties",
          style: TextStyle(
            color: Color(0xFF1D3557),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade200,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : listings.isEmpty
              ? const Center(child: Text("No listings found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final p = listings[index];

                    final address = p["location"]?["address"];
                    final line = address?["line"] ?? "No Address";
                    final city = address?["city"] ?? "";
                    final stateCode = address?["state_code"] ?? "";
                    final postalCode = address?["postal_code"] ?? "";

                    final desc = p["description"] ?? {};
                    final beds = desc["beds"] ?? 0;
                    final baths = desc["baths"] ?? 0;
                    final sqft = desc["sqft"] ?? 0;

                    final price = p["list_price"] ?? p["price"] ?? 0;

                    final hdImage = getStreetViewImage(p);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: hdImage.isEmpty
                                ? Container(
                                    height: 240,
                                    width: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.house,
                                      size: 70,
                                      color: Colors.white,
                                    ),
                                  )
                                : Image.network(
                                    hdImage,
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.high,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D3557),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$city, $stateCode $postalCode",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "\$${price.toString()}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "$beds beds • $baths baths • $sqft sqft",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}