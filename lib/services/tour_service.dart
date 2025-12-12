import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TourService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  Future<void> requestTour({
    required String propertyId,
    required String sellerId,
    required String tourType,
    required String date,
    required String time,

    // ✅ NEW: store property snapshot for easy display later
    required Map<String, dynamic> propertySnapshot,
  }) async {
    await _db.collection("tour_requests").add({
      "propertyId": propertyId,
      "buyerId": _uid,
      "sellerId": sellerId,
      "tourType": tourType,
      "date": date,
      "time": time,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),

      
      "propertySnapshot": propertySnapshot,
    });
  }

  Stream<QuerySnapshot> sellerRequests() {
    return _db
        .collection("tour_requests")
        .where("sellerId", isEqualTo: _uid)
        .snapshots();
  }

  Stream<QuerySnapshot> buyerRequests() {
    return _db
        .collection("tour_requests")
        .where("buyerId", isEqualTo: _uid)
        .snapshots();
  }

  Future<void> updateStatus(String docId, String status) async {
    await _db.collection("tour_requests").doc(docId).update({
      "status": status,
    });
  }

  Future<void> cancelTour(String docId) async {
    await _db.collection("tour_requests").doc(docId).delete();
  }

  Future<List<String>> getAvailableSlots({
    required String propertyId,
    required String date,
  }) async {
    final snap = await _db
        .collection("tour_requests")
        .where("propertyId", isEqualTo: propertyId)
        .where("date", isEqualTo: date)
        .where("status", isEqualTo: "approved")
        .get();

    final bookedTimes = snap.docs
        .map((d) => (d.data()["time"] ?? "").toString())
        .where((t) => t.isNotEmpty)
        .toSet();

    final allSlots = [
      "9:00 AM",
      "10:00 AM",
      "11:00 AM",
      "12:00 PM",
      "1:00 PM",
      "2:00 PM",
      "3:00 PM",
      "4:00 PM",
      "5:00 PM",
    ];

    return allSlots.where((s) => !bookedTimes.contains(s)).toList();
  }
}