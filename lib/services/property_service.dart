import 'dart:convert';
import 'package:http/http.dart' as http;

class PropertyService {
  final String endpoint =
      "https://us-central1-property-pulse-app-melkamu.cloudfunctions.net/getListings";

  Future<List<dynamic>> getListings() async {
    final url = Uri.parse(endpoint);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Realty-In-US structure:
      // { "data": { "home_search": { "results": [ ... ] } } }
      final results =
          data["data"]?["home_search"]?["results"] as List<dynamic>?;

      return results ?? [];
    } else {
      throw Exception("Failed to load real estate listings");
    }
  }
}