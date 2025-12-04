import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property.dart';

class PropertyService {
  final String baseUrl =
      "https://us-central1-property-pulse-app-melkamu.cloudfunctions.net/getListings";

  Future<List<Property>> fetchListings() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      final List results = jsonData['results'] ?? [];

      return results.map((e) => Property.fromJson(e)).toList();
    } else {
      return [];
    }
  }
}