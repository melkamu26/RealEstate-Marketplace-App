import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String text;
  final String senderId;
  final DateTime timestamp;

  MessageModel({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final ts = json["timestamp"];

    return MessageModel(
      text: json["text"] ?? "",
      senderId: json["senderId"] ?? "",
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "senderId": senderId,
      "timestamp": Timestamp.fromDate(timestamp),
    };
  }
}