import 'package:flutter/material.dart';

import '../../models/property.dart';
import '../../services/tour_service.dart';
import '../../widgets/property_card.dart';
import '../home/property_detail_screen.dart';
import 'schedule_tour_screen.dart';

class BuyerTourDetailScreen extends StatelessWidget {
  final String tourId;
  final Map<String, dynamic> tourData;

  const BuyerTourDetailScreen({
    super.key,
    required this.tourId,
    required this.tourData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = TourService();

    final date = (tourData["date"] ?? "-").toString();
    final time = (tourData["time"] ?? "-").toString();
    final type = (tourData["tourType"] ?? "Tour").toString();
    final status = (tourData["status"] ?? "pending").toString();

    final snap = tourData["propertySnapshot"];

    /// SAFETY CHECK
    if (snap == null || snap is! Map<String, dynamic>) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Tour Details"),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "Property not found.\nThis tour was created before property data was saved.\nPlease create a new tour request.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final property = Property.fromMap(snap);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Tour Details"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ================= PROPERTY CARD =================
          PropertyCard(
            property: property,
            isFavorite: false,
            isCompared: false,
            onFavoriteToggle: () {},
            onCompareToggle: () {},
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PropertyDetailScreen(property: property),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          /// ================= TOUR INFO CARD =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tour Information",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                _infoRow("Type", type),
                _infoRow("Date", date),
                _infoRow("Time", time),
                _infoRow("Status", status.toUpperCase()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          /// ================= ACTION BUTTONS =================
          Row(
            children: [
              /// CANCEL
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    _confirmCancel(
                      context: context,
                      service: service,
                    );
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// RESCHEDULE
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    _confirmReschedule(
                      context: context,
                      service: service,
                      property: property,
                    );
                  },
                  child: const Text(
                    "Reschedule",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ================= CONFIRM CANCEL =================
  void _confirmCancel({
    required BuildContext context,
    required TourService service,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Tour"),
        content:
            const Text("Are you sure you want to cancel this tour?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              await service.cancelTour(tourId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Yes, Cancel",
              style:
                  TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= CONFIRM RESCHEDULE =================
  void _confirmReschedule({
    required BuildContext context,
    required TourService service,
    required Property property,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reschedule Tour"),
        content: const Text(
          "This will cancel your current tour and let you pick a new date and time.\n\nContinue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              /// DELETE OLD TOUR FIRST
              await service.cancelTour(tourId);
              if (!context.mounted) return;

              /// GO TO SCHEDULE SCREEN
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ScheduleTourScreen(
                    property: property,
                    sellerId: property.sellerId,
                  ),
                ),
              );
            },
            child: const Text(
              "Yes, Reschedule",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= INFO ROW =================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}