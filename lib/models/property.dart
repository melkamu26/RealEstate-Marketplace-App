class Property {
  final String propertyId;
  final String listingId;

  final String address;
  final String city;
  final String state;

  final String price;
  final String beds;
  final String baths;
  final String sqft;

  final String imageUrl;
  final String streetViewUrl;

  final double latitude;
  final double longitude;

  List<String> images; // gallery photos

  Property({
    required this.propertyId,
    required this.listingId,
    required this.address,
    required this.city,
    required this.state,
    required this.price,
    required this.beds,
    required this.baths,
    required this.sqft,
    required this.imageUrl,
    required this.streetViewUrl,
    required this.latitude,
    required this.longitude,
    required this.images,
  });

  // HD FIX
  static String fixHD(String url) {
    if (url.contains("s.jpg")) {
      return url.replaceAll("s.jpg", "l.jpg");
    }
    return url;
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    final loc = json["location"]?["address"] ?? {};
    final coord = loc["coordinate"] ?? {};
    final primary = json["primary_photo"];

    String img = primary?["href"] ?? "";
    img = fixHD(img);

    return Property(
      propertyId: json["property_id"] ?? "",
      listingId: json["listing_id"] ?? "",

      address: loc["line"] ?? "Unknown",
      city: loc["city"] ?? "",
      state: loc["state_code"] ?? "",

      price: json["list_price"]?.toString() ?? "0",
      beds: json["description"]?["beds"]?.toString() ?? "0",
      baths: json["description"]?["baths"]?.toString() ?? "0",
      sqft: json["description"]?["sqft"]?.toString() ?? "0",

      imageUrl: img,
      streetViewUrl: json["location"]?["street_view_url"] ?? "",

      latitude: (coord["lat"] ?? 0).toDouble(),
      longitude: (coord["lon"] ?? 0).toDouble(),

      images: [], // gallery starts empty
    );
  }
}
