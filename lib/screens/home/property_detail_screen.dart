import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../chat/chat_screen.dart';
import '../tour/schedule_tour_screen.dart';
import 'gallery_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

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
    _loadImages();
    _loadFavorite();
  }

  Future<void> _loadImages() async {
    final result =
        await service.fetchGalleryPhotos(widget.property.propertyId);
    if (!mounted) return;
    setState(() {
      photos = result;
      loading = false;
    });
  }

  Future<void> _loadFavorite() async {
    final fav = await service.isFavorite(widget.property.propertyId);
    if (!mounted) return;
    setState(() => isFavorite = fav);
  }

  bool _isLand(String type) {
    final t = type.toLowerCase();
    return t.contains("land") || t.contains("lot");
  }

  String _prettyType(String type) {
    final t = type.toLowerCase();
    if (t.contains("condo") || t.contains("apartment")) {
      return "Apartment / Condo";
    }
    if (t.contains("town")) return "Townhouse";
    if (t.contains("land") || t.contains("lot")) return "Land / Lot";
    return "Single Family";
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(p.address),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: () async {
              setState(() => isFavorite = !isFavorite);
              if (isFavorite) {
                await service.addFavorite(p);
              } else {
                await service.removeFavorite(p.propertyId);
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HERO IMAGE
                  Image.network(
                    photos.isNotEmpty ? photos.first : p.cardImage,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  /// THUMBNAILS
                  if (photos.length > 1)
                    SizedBox(
                      height: 95,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        itemCount: photos.length,
                        itemBuilder: (_, i) => GestureDetector(
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
                            width: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(photos[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  /// PRICE CARD
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "\$${p.formattedPrice}",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${p.beds} beds • ${p.baths} baths • ${p.sqft} sqft",
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.address,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text("${p.city}, ${p.state}"),
                      ],
                    ),
                  ),

                  /// INFO GRID
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                      children: [
                        _infoBox(Icons.home, _prettyType(p.type)),
                        _infoBox(Icons.square_foot, "${p.sqft} sqft"),
                        _infoBox(Icons.bed, "${p.beds} Bedrooms"),
                        _infoBox(Icons.bathtub, "${p.baths} Bathrooms"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LOCATION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Location",
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// STREET VIEW IMAGE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: p.streetViewUrl.isNotEmpty
                          ? Image.network(
                              p.streetViewUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 200,
                              color: theme.dividerColor.withOpacity(0.15),
                              child: const Center(
                                child: Text("No street view available"),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// MAP BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.streetview),
                            label: const Text("Street View"),
                            onPressed: p.streetViewUrl.isEmpty
                                ? null
                                : () => PropertyService.openUrl(
                                      p.streetViewUrl,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text("Google Maps"),
                            onPressed: () {
                              final url =
                                  "https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}";
                              PropertyService.openUrl(url);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACTION BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Message Agent"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatScreen(propertyId: p.propertyId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            _isLand(p.type)
                                ? "Tour Not Available"
                                : "Schedule Tour",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLand(p.type)
                                ? theme.disabledColor
                                : Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLand(p.type)
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScheduleTourScreen(
                                        property: p,
                                        sellerId: p.sellerId,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}