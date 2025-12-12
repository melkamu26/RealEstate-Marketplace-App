import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/tour_service.dart';

class BuyerTourRequestsScreen extends StatelessWidget {
  BuyerTourRequestsScreen({super.key});

  final TourService service = TourService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tour Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.buyerRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("No tour requests yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    "${data["tourType"] ?? "Tour"}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: ${data["date"] ?? "-"}"),
                      Text("Time: ${data["time"] ?? "-"}"),
                      Text("Status: ${data["status"] ?? "-"}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}