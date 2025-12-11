import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../chat/chat_screen.dart';
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
    final result = await service.fetchGalleryPhotos(widget.property.propertyId);

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
    setState(() => isFavorite = nowFav);

    try {
      if (nowFav) {
        await service.addFavorite(widget.property);
      } else {
        await service.removeFavorite(widget.property.propertyId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isFavorite = !nowFav);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.property;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          p.address,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.primaryColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : theme.iconTheme.color,
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
                  /// MAIN IMAGE
                  Image.network(
                    photos.isNotEmpty ? photos.first : p.cardImage,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 250,
                      color: theme.colorScheme.surfaceVariant,
                      child: const Center(child: Text("No Image")),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// GALLERY
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
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
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

                  /// PRICE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "\$${p.formattedPrice}",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// BEDS / BATHS / SQFT
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "${p.beds} beds • ${p.baths} baths • ${p.sqft} sqft",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  /// STREET VIEW
                  if (p.streetViewUrl.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Google Street View",
                            style: theme.textTheme.titleMedium?.copyWith(
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

                  /// OPEN IN MAPS BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      onPressed: () {
                        final url =
                            "https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}";
                        PropertyService.openUrl(url);
                      },
                      child: const Text("Open in Google Maps",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// MESSAGE AGENT BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(propertyId: p.propertyId),
                          ),
                        );
                      },
                      child: const Text("Message Agent",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}