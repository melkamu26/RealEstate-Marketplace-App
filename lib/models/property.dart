class Property {
  final String address;
  final String city;
  final String state;
  final String price;
  final String beds;
  final String baths;
  final String sqft;
  final String imageUrl;
  final String? streetViewUrl;
  final double latitude;
  final double longitude;

  Property({
    required this.address,
    required this.city,
    required this.state,
    required this.price,
    required this.beds,
    required this.baths,
    required this.sqft,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.streetViewUrl,
  });

  factory Property.fromJson(Map json) {
    final loc = json["location"]["address"];
    final primary = json["primary_photo"];

    // FIX BLUR → convert small images (s.jpg) to large images (l.jpg)
    String img = primary?["href"] ?? "";
    if (img.contains("s.jpg")) {
      img = img.replaceAll("s.jpg", "l.jpg");
    }

    return Property(
      address: loc["line"] ?? "Unknown",
      city: loc["city"] ?? "",
      state: loc["state_code"] ?? "",
      price: json["list_price"]?.toString() ?? "0",
      beds: json["description"]["beds"]?.toString() ?? "0",
      baths: json["description"]["baths"]?.toString() ?? "0",
      sqft: json["description"]["sqft"]?.toString() ?? "0",
      imageUrl: img,
      latitude: loc["coordinate"]["lat"] ?? 0.0,
      longitude: loc["coordinate"]["lon"] ?? 0.0,
      streetViewUrl: json["location"]["street_view_url"],
    );
  }
}