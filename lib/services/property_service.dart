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

  // Compare collection
  CollectionReference<Map<String, dynamic>> get compareRef =>
      FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("compare");

  // Open URL
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw "Could not open URL";
    }
  }

  // ---------------------------
  // Fetch Home Listings
  // ---------------------------

  Future<List<Property>> fetchListings() async {
    final url = Uri.parse("$baseURL/getListings");
    final res = await http.get(url);

    final data = jsonDecode(res.body);
    final results = data["data"]["home_search"]["results"] as List<dynamic>;

    List<Property> list = results.map((e) => Property.fromJson(e)).toList();

    // Remove duplicates
    final Map<String, Property> unique = {};
    for (final p in list) {
      unique[p.propertyId] = p;
    }

    return unique.values.toList();
  }

  // ---------------------------
  // Search Properties
  // ---------------------------

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

  // ---------------------------
  // Gallery Photos
  // ---------------------------

  Future<List<String>> fetchGalleryPhotos(String propertyId) async {
    final url = Uri.parse("$baseURL/getPropertyPhotos?property_id=$propertyId");

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final json = jsonDecode(res.body);
    final photos = json["photos"];
    if (photos == null) return [];

    return List<String>.from(photos.map((p) => Property.fixHD(p)));
  }

  // ---------------------------
  // FAVORITES
  // ---------------------------

  Future<void> addFavorite(Property p) async {
    await favRef.doc(p.propertyId).set({
      ...p.toMap(),
      "imageUrl": p.cardImage,
    });
  }

  Future<void> removeFavorite(String id) async {
    await favRef.doc(id).delete();
  }

  Future<Set<String>> getFavorites() async {
    final snap = await favRef.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<bool> isFavorite(String id) async {
    final doc = await favRef.doc(id).get();
    return doc.exists;
  }

  // ---------------------------
  // COMPARISON FEATURE
  // ---------------------------

  Future<Set<String>> getCompareList() async {
    final snap = await compareRef.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  Future<void> addToCompare(Property p) async {
    await compareRef.doc(p.propertyId).set({
      ...p.toMap(),
      "imageUrl": p.cardImage,
    });
  }

  Future<void> removeFromCompare(String id) async {
    await compareRef.doc(id).delete();
  }

  Future<bool> isInCompare(String id) async {
    final doc = await compareRef.doc(id).get();
    return doc.exists;
  }

  // Load full compared properties
  Future<List<Property>> loadComparedProperties() async {
    final snap = await compareRef.get();
    return snap.docs.map((d) => Property.fromMap(d.data())).toList();
  }

  // Clear compare list
  Future<void> clearCompare() async {
    final snap = await compareRef.get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
