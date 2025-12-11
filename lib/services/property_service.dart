import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/property.dart';

class PropertyService {
  final String baseURL =
      "https://us-central1-property-pulse-app-melkamu.cloudfunctions.net";

  // Logged-in user
  User? get user => FirebaseAuth.instance.currentUser;

  // Favorites collection
  CollectionReference<Map<String, dynamic>> get favRef =>
      FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("favorites");

  // Open URL
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "Could not open URL";
    }
  }

  //  Fetch Home Listings
  Future<List<Property>> fetchListings() async {
    final url = Uri.parse("$baseURL/getListings");
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final results = data["data"]["home_search"]["results"] as List<dynamic>;

    List<Property> list = results.map((e) => Property.fromJson(e)).toList();

    final Map<String, Property> unique = {};
    for (final p in list) {
      unique[p.propertyId] = p;
    }

    return unique.values.toList();
  }

  // Search Properties
  Future<List<Property>> searchProperties({
    required String city,
    required String state,
    required String maxPrice,
    required String propertyType,
  }) async {
    final url = Uri.parse(
        "$baseURL/searchProperties?city=$city&state=$state&maxPrice=$maxPrice&type=$propertyType");

    final res = await http.get(url);
    final body = jsonDecode(res.body);

    List<dynamic> results = body["data"]["home_search"]["results"];
    List<Property> list = results.map((e) => Property.fromJson(e)).toList();

    // Price filter
    final maxP = int.tryParse(maxPrice) ?? 999999999;
    list = list.where((p) => p.priceInt <= maxP).toList();

    // Type filter
    final typeMap = {
      "House": "single_family",
      "Apartment": "condos",
      "Townhouse": "townhomes",
      "Multi-Family": "multi_family",
      "Land / Lot": "land",
    };

    final mapped = typeMap[propertyType] ?? "";
    if (mapped.isNotEmpty) {
      list = list.where((p) => p.type == mapped).toList();
    }

    // Remove duplicates
    final Map<String, Property> unique = {};
    for (final p in list) {
      unique[p.propertyId] = p;
    }

    return unique.values.toList();
  }

  // Fetch Gallery Photos
  Future<List<String>> fetchGalleryPhotos(String propertyId) async {
    final url = Uri.parse("$baseURL/getPropertyPhotos?property_id=$propertyId");

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body);
    final photos = json["photos"];

    if (photos == null) return [];

    return List<String>.from(photos.map((p) => Property.fixHD(p)));
  }

  //  Add Favorite (FIXED to save correct image)
  Future<void> addFavorite(Property p) async {
    await favRef.doc(p.propertyId).set({
      ...p.toMap(),
      "imageUrl": p.cardImage, // force correct image
    });
  }

  // Remove Favorite
  Future<void> removeFavorite(String id) async {
    await favRef.doc(id).delete();
  }

  // Load Favorite IDs
  Future<Set<String>> getFavorites() async {
    final snap = await favRef.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  // Check Favorite
  Future<bool> isFavorite(String id) async {
    final doc = await favRef.doc(id).get();
    return doc.exists;
  }
}