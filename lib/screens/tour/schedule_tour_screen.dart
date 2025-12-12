import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../services/tour_service.dart';

class ScheduleTourScreen extends StatefulWidget {
  final Property property; //  changed
  final String sellerId;

  const ScheduleTourScreen({
    super.key,
    required this.property,
    required this.sellerId,
  });

  @override
  State<ScheduleTourScreen> createState() => _ScheduleTourScreenState();
}

class _ScheduleTourScreenState extends State<ScheduleTourScreen> {
  final TourService service = TourService();
  final TextEditingController dateController = TextEditingController();

  String selectedTourType = "Virtual";
  String selectedDate = "";
  String selectedTime = "";

  List<String> availableSlots = [];
  bool loadingSlots = false;

  Future<void> loadSlots() async {
    if (selectedDate.isEmpty) return;

    setState(() => loadingSlots = true);

    availableSlots = await service.getAvailableSlots(
      propertyId: widget.property.propertyId,
      date: selectedDate,
    );

    setState(() => loadingSlots = false);
  }

  Future<void> submitRequest() async {
    if (selectedDate.isEmpty || selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date and time")),
      );
      return;
    }

    await service.requestTour(
      propertyId: widget.property.propertyId,
      sellerId: widget.sellerId,
      tourType: selectedTourType,
      date: selectedDate,
      time: selectedTime,

      // 
      propertySnapshot: widget.property.toMap(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tour request sent")),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Schedule a Tour"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tour Type",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                _tourTypeButton("Virtual", Icons.videocam),
                const SizedBox(width: 12),
                _tourTypeButton("In-Person", Icons.home),
              ],
            ),

            const SizedBox(height: 24),

            Text("Select Date",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Choose a date",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate = "${picked.year}-${picked.month}-${picked.day}";
                    dateController.text = selectedDate;
                    selectedTime = "";
                    availableSlots.clear();
                  });
                  await loadSlots();
                }
              },
            ),

            const SizedBox(height: 24),

            Text("Available Time Slots",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (loadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (availableSlots.isEmpty && selectedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "No available slots for this date",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableSlots.map((slot) {
                  final selected = slot == selectedTime;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: selected,
                    onSelected: (_) => setState(() => selectedTime = slot),
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selected ? theme.colorScheme.onPrimary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: submitRequest,
          child: const Text(
            "Request Tour",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _tourTypeButton(String type, IconData icon) {
    final theme = Theme.of(context);
    final selected = selectedTourType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTourType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? theme.colorScheme.onPrimary : theme.iconTheme.color),
              const SizedBox(height: 6),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? theme.colorScheme.onPrimary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}