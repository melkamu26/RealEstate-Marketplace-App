import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/property.dart';

class PropertyService {
  final String baseURL =
      "https://us-central1-property-pulse-app-melkamu.cloudfunctions.net";

  // MAIN LISTINGS
  Future<List<Property>> fetchListings() async {
    final url = Uri.parse("$baseURL/getListings");
    final response = await http.get(url);

    final body = jsonDecode(response.body);
    final results = body["data"]["home_search"]["results"] as List<dynamic>;

    return results.map((e) => Property.fromJson(e)).toList();
  }

  // ADVANCED SEARCH (CITY + STATE + MAX PRICE + TYPE)
  Future<List<Property>> searchProperties({
    required String city,
    required String state,
    required String maxPrice,
    required String propertyType,
  }) async {
    final url = Uri.parse(
        "$baseURL/searchProperties?city=$city&state=$state&maxPrice=$maxPrice&type=$propertyType");

    final response = await http.get(url);
    final body = jsonDecode(response.body);

    final results = body["data"]["home_search"]["results"] as List<dynamic>;
    return results.map((e) => Property.fromJson(e)).toList();
  }

  // PROPERTY PHOTOS
  Future<List<String>> fetchGalleryPhotos(String propertyId) async {
    final url = Uri.parse("$baseURL/getPropertyPhotos?property_id=$propertyId");
    final response = await http.get(url);

    final json = jsonDecode(response.body);
    final photos = json["data"]?["home_search"]?["results"]?[0]?["photos"];

    if (photos == null) return [];
    return photos.map<String>((p) => Property.fixHD(p["href"])).toList();
  }
}