import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import 'gallery_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PropertyService service = PropertyService();

  List<String> photos = [];
  bool loading = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    loadFavoriteStatus();
    loadImages();
  }

  Future<void> loadFavoriteStatus() async {
    final exists = await service.isFavorite(widget.property.propertyId);
    if (!mounted) return;
    setState(() {
      isFavorite = exists;
    });
  }

  Future<void> loadImages() async {
    final result =
        await service.fetchGalleryPhotos(widget.property.propertyId);

    if (!mounted) return;
    setState(() {
      photos = result;
      loading = false;
    });
  }

  Future<void> toggleFavorite() async {
    final user = service.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in to save favorites")),
      );
      return;
    }

    final nowFav = !isFavorite;
    setState(() {
      isFavorite = nowFav;
    });

    try {
      if (nowFav) {
        await service.addFavorite(widget.property);
      } else {
        await service.removeFavorite(widget.property.propertyId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isFavorite = !nowFav;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.address),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: toggleFavorite,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    photos.isNotEmpty ? photos.first : p.cardImage,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 250,
                      child: Center(child: Text("No Image")),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (photos.length > 1)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (_, i) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GalleryScreen(
                                    images: photos,
                                    startIndex: i,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 150,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(photos[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "\$${p.formattedPrice}",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "${p.beds} beds • ${p.baths} baths • ${p.sqft} sqft",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (p.streetViewUrl.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Google Street View",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          p.streetViewUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      onPressed: () {
                        final url =
                            "https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}";
                        PropertyService.openUrl(url);
                      },
                      child: const Text(
                        "Open in Google Maps",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}