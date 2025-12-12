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

  final String type;
  final String listingUrl;

  final String sellerId;

  List<String> images;

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
    required this.type,
    required this.listingUrl,
    required this.sellerId,
    required this.images,
  });

  static String fixHD(String url) {
    if (url.contains("s.jpg")) {
      return url.replaceAll("s.jpg", "l.jpg");
    }
    return url;
  }

  int get priceInt =>
      int.tryParse(price.replaceAll(",", "").trim()) ?? 0;

  String get formattedPrice {
    final v = priceInt;
    if (v == 0) return "0";

    final s = v.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final left = s.length - i - 1;
      if (left > 0 && left % 3 == 0) buffer.write(",");
    }

    return buffer.toString();
  }

  String get cardImage {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (streetViewUrl.isNotEmpty) return streetViewUrl;
    return "";
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    final loc = json["location"]?["address"] ?? {};
    final coord = loc["coordinate"] ?? {};
    final primary = json["primary_photo"];

    return Property(
      propertyId: json["property_id"]?.toString() ?? "",
      listingId: json["listing_id"]?.toString() ?? "",
      address: loc["line"] ?? "Unknown",
      city: loc["city"] ?? "",
      state: loc["state_code"] ?? "",
      price: json["list_price"]?.toString() ?? "0",
      beds: json["description"]?["beds"]?.toString() ?? "0",
      baths: json["description"]?["baths"]?.toString() ?? "0",
      sqft: json["description"]?["sqft"]?.toString() ?? "0",
      imageUrl: fixHD(primary?["href"] ?? ""),
      streetViewUrl: json["location"]?["street_view_url"] ?? "",
      latitude: (coord["lat"] ?? 0).toDouble(),
      longitude: (coord["lon"] ?? 0).toDouble(),
      type: json["description"]?["type"]?.toString().toLowerCase() ?? "",
      listingUrl: json["href"]?.toString() ?? "",
      sellerId: json["seller_id"]?.toString() ?? "admin",
      images: [],
    );
  }

  Map<String, dynamic> toMap() => {
        "propertyId": propertyId,
        "listingId": listingId,
        "address": address,
        "city": city,
        "state": state,
        "price": price,
        "beds": beds,
        "baths": baths,
        "sqft": sqft,
        "imageUrl": imageUrl,
        "streetViewUrl": streetViewUrl,
        "latitude": latitude,
        "longitude": longitude,
        "type": type,
        "listingUrl": listingUrl,
        "sellerId": sellerId,
        "images": images,
      };

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      propertyId: map["propertyId"] ?? "",
      listingId: map["listingId"] ?? "",
      address: map["address"] ?? "",
      city: map["city"] ?? "",
      state: map["state"] ?? "",
      price: map["price"] ?? "0",
      beds: map["beds"] ?? "0",
      baths: map["baths"] ?? "0",
      sqft: map["sqft"] ?? "0",
      imageUrl: map["imageUrl"] ?? "",
      streetViewUrl: map["streetViewUrl"] ?? "",
      latitude: (map["latitude"] is num) ? map["latitude"].toDouble() : 0.0,
      longitude: (map["longitude"] is num) ? map["longitude"].toDouble() : 0.0,
      type: map["type"]?.toString().toLowerCase() ?? "",
      listingUrl: map["listingUrl"] ?? "",
      sellerId: map["sellerId"] ?? "admin",
      images: (map["images"] is List)
          ? List<String>.from(map["images"])
          : [],
    );
  }
}