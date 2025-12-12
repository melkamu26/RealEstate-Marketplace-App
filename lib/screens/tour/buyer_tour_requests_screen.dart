import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/tour_service.dart';
import 'buyer_tour_detail_screen.dart';

class BuyerTourRequestsScreen extends StatelessWidget {
  BuyerTourRequestsScreen({super.key});

  final TourService service = TourService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "My Tour Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: isDark ? 0 : 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.buyerRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _emptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final tourType = (data["tourType"] ?? "Tour").toString();
              final date = (data["date"] ?? "-").toString();
              final time = (data["time"] ?? "-").toString();
              final status = (data["status"] ?? "pending").toString();

              final statusColor = _statusColor(status);
              final canCancel =
                  status != "rejected" && status != "cancelled";

              return InkWell(
                borderRadius: BorderRadius.circular(18),

            
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BuyerTourDetailScreen(
                        tourId: doc.id,
                        tourData: data,
                      ),
                    ),
                  );
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.transparent
                          : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDark ? 0.25 : 0.06,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tourType,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _statusChip(status, statusColor),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// DATE & TIME
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      if (canCancel) ...[
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              backgroundColor: isDark
                                  ? Colors.transparent
                                  : Colors.red.withOpacity(0.04),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _confirmCancel(context, doc.id),
                            child: const Text(
                              "Cancel Tour",
                              style: TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
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

  /// CONFIRM CANCEL
  void _confirmCancel(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Tour"),
        content: const Text(
            "Are you sure you want to cancel this tour request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              await service.cancelTour(docId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// STATUS CHIP
  Widget _statusChip(String status, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 90,
              color: isDark
                  ? Colors.grey[600]
                  : Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              "No Tour Requests",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your scheduled tours will appear here.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return const Center(
      child: Text(
        "Something went wrong.\nPlease try again later.",
        textAlign: TextAlign.center,
      ),
    );
  }
}