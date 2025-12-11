import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();

    if (service.user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to see your favorites")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.favRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No favorites yet"));
          }

          final properties =
              docs.map((doc) => Property.fromMap(doc.data())).toList();

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (_, i) {
              final p = properties[i];

              return PropertyCard(
                property: p,
                isFavorite: true,

                // remove
                onFavoriteToggle: () async {
                  await service.removeFavorite(p.propertyId);
                },

               
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: p),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}