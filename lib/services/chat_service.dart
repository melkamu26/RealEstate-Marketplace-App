import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  /// COLLECTIONS
  CollectionReference get supportRef =>
      firestore.collection("support_chat");

  DocumentReference get supportMeta =>
      firestore.collection("support_chat_meta").doc("meta");

  CollectionReference propertyRef(String propertyId) =>
      firestore.collection("property_chat")
          .doc(propertyId)
          .collection("messages");

  DocumentReference propertyMeta(String propertyId) =>
      firestore.collection("property_chat")
          .doc(propertyId)
          .collection("meta")
          .doc("meta");


  /// STREAMS
  Stream<QuerySnapshot> getSupportMessages() =>
      supportRef.orderBy("timestamp").snapshots();

  Stream<QuerySnapshot> getPropertyMessages(String propertyId) =>
      propertyRef(propertyId).orderBy("timestamp").snapshots();


  /// SEND USER MESSAGE (SUPPORT)
  Future<void> sendSupportMessage(String text) async {
    await supportRef.add({
      "senderId": user!.uid,
      "text": text,
      "timestamp": DateTime.now(),
      "seen": false,
    });

    _autoRespondSupport();
  }

  /// SEND USER MESSAGE (PROPERTY CHAT)
  Future<void> sendPropertyMessage(String propertyId, String text) async {
    await propertyRef(propertyId).add({
      "senderId": user!.uid,
      "text": text,
      "timestamp": DateTime.now(),
      "seen": false,
    });

    _autoRespondProperty(propertyId);
  }


  
  // AUTO BOT RESPONSE (SUPPORT CHAT)
  
  Future<void> _autoRespondSupport() async {
    final meta = await supportMeta.get();

    // If bot already replied once, never reply again
    if (meta.exists && meta["hasReplied"] == true) return;

    await Future.delayed(const Duration(seconds: 30));

    // FIRST MESSAGE
    await supportRef.add({
      "senderId": "agent_bot",
      "text": "Thanks for reaching support! How can I help you today?",
      "timestamp": DateTime.now(),
      "seen": false,
    });

    await Future.delayed(const Duration(seconds: 30));

    // SECOND MESSAGE
    await supportRef.add({
      "senderId": "agent_bot",
      "text": "Your question was received. An agent will reply shortly.",
      "timestamp": DateTime.now(),
      "seen": false,
    });

    // Save state → prevents spam responses
    await supportMeta.set({"hasReplied": true});
  }


  
  // AUTO BOT RESPONSE (PROPERTY CHAT)
  

  Future<void> _autoRespondProperty(String propertyId) async {
    final meta = await propertyMeta(propertyId).get();

    if (meta.exists && meta["hasReplied"] == true) return;

    await Future.delayed(const Duration(seconds: 1));

    await propertyRef(propertyId).add({
      "senderId": "agent_bot",
      "text": "Thanks for your interest! An agent will reach out shortly.",
      "timestamp": DateTime.now(),
      "seen": false,
    });

    await propertyMeta(propertyId).set({"hasReplied": true});
  }


  //  MARK MESSAGES AS SEEN


  Future<void> markSeen(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      if (doc["senderId"] != user!.uid && doc["seen"] == false) {
        await doc.reference.update({"seen": true});
      }
    }
  }

 
  // OPTIONAL: CLEAR CHAT FOR TESTING (not used in UI)


  Future<void> resetSupportBot() async {
    await supportMeta.set({"hasReplied": false});
  }
}