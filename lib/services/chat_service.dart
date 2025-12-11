import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  /// Each user gets their own support chat
  CollectionReference get supportMessages =>
      firestore.collection("support_chat").doc(user!.uid).collection("messages");

  /// For property chat (already private because propertyId is unique)
  CollectionReference propertyMessages(String propertyId) =>
      firestore.collection("property_chat")
          .doc(propertyId)
          .collection("messages");

  /// STREAMS
  Stream<QuerySnapshot> getSupportMessages() =>
      supportMessages.orderBy("timestamp").snapshots();

  Stream<QuerySnapshot> getPropertyMessages(String propertyId) =>
      propertyMessages(propertyId).orderBy("timestamp").snapshots();

  /// SEND MESSAGE
  Future<void> sendSupportMessage(String text) async {
    await supportMessages.add({
      "senderId": user!.uid,
      "text": text,
      "timestamp": DateTime.now(),
    });

    _autoSupportReply();
  }

  Future<void> sendPropertyMessage(String propertyId, String text) async {
    await propertyMessages(propertyId).add({
      "senderId": user!.uid,
      "text": text,
      "timestamp": DateTime.now(),
    });

    _autoPropertyReply(propertyId);
  }

  /// BOT AUTO REPLY
  Future<void> _autoSupportReply() async {
    await Future.delayed(const Duration(seconds: 2));
    await supportMessages.add({
      "senderId": "agent_bot",
      "text": "Your question was received. An agent will reply shortly.",
      "timestamp": DateTime.now(),
    });
  }

  Future<void> _autoPropertyReply(String propertyId) async {
    await Future.delayed(const Duration(seconds: 2));
    await propertyMessages(propertyId).add({
      "senderId": "agent_bot",
      "text": "Thanks for your message! An agent will respond soon.",
      "timestamp": DateTime.now(),
    });
  }
}