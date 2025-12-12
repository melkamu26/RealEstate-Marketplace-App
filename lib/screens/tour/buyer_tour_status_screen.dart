import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/tour_service.dart';

class BuyerTourStatusScreen extends StatelessWidget {
  BuyerTourStatusScreen({super.key});

  final TourService service = TourService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Tour Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.buyerRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("Firestore error: ${snapshot.error}");
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
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final tourType = data["tourType"] ?? "Unknown";
              final date = data["date"] ?? "N/A";
              final time = data["time"] ?? "N/A";
              final status = data["status"] ?? "pending";

              Color statusColor = Colors.orange;
              if (status == "approved") statusColor = Colors.green;
              if (status == "rejected") statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tourType,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text("Date: $date"),
                      Text("Time: $time"),
                      const SizedBox(height: 10),
                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
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