import 'package:flutter/material.dart';
import '../../services/tour_service.dart';

class ScheduleTourScreen extends StatefulWidget {
  final String propertyId;
  final String sellerId;

  const ScheduleTourScreen({
    super.key,
    required this.propertyId,
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
      propertyId: widget.propertyId,
      date: selectedDate,
    );

    setState(() => loadingSlots = false);
  }

  Future<void> submitRequest() async {
    if (selectedDate.isEmpty || selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date and time")),
      );
      return;
    }

    await service.requestTour(
      propertyId: widget.propertyId,
      sellerId: widget.sellerId,
      tourType: selectedTourType,
      date: selectedDate,
      time: selectedTime,
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
    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Tour")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedTourType,
              items: const [
                DropdownMenuItem(value: "Virtual", child: Text("Virtual Tour")),
                DropdownMenuItem(value: "In-Person", child: Text("In-Person Tour")),
              ],
              onChanged: (v) => setState(() => selectedTourType = v!),
              decoration: const InputDecoration(labelText: "Tour Type"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Select Date"),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );

                if (picked != null) {
                  setState(() {
                    selectedDate =
                        "${picked.year}-${picked.month}-${picked.day}";
                    dateController.text = selectedDate;
                    selectedTime = "";
                    availableSlots.clear();
                  });

                  await loadSlots();
                }
              },
            ),

            const SizedBox(height: 20),

            if (loadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (availableSlots.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedTime.isEmpty ? null : selectedTime,
                items: availableSlots
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedTime = v!),
                decoration: const InputDecoration(labelText: "Time Slot"),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitRequest,
                child: const Text("Request Tour"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}