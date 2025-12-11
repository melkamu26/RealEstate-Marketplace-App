import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String? propertyId;

  const ChatScreen({super.key, this.propertyId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chat = ChatService();
  final msgController = TextEditingController();
  final scrollController = ScrollController();

  bool agentTyping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyId == null
            ? "Support Chat"
            : "Ask About Property"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.propertyId == null
                  ? chat.getSupportMessages()
                  : chat.getPropertyMessages(widget.propertyId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                chat.markSeen(snapshot.data!);

                final docs = snapshot.data!.docs;

                // Agent typing animation condition
                if (docs.isNotEmpty) {
                  final lastSender = docs.last["senderId"];
                  agentTyping = lastSender == "agent_bot";
                }

                // Auto-scroll
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == chat.user!.uid;

                    return Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            data["text"],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _formatTime(data["timestamp"]),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // TYPING INDICATOR
          if (agentTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: const [
                  Text("Agent is typing...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // TEXT BOX
          _messageBox(),
        ],
      ),
    );
  }

  Widget _messageBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: msgController,
              decoration: const InputDecoration(
                hintText: "Type your message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue, size: 30),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }

  void sendMessage() {
    final text = msgController.text.trim();
    if (text.isEmpty) return;

    if (widget.propertyId == null) {
      chat.sendSupportMessage(text);
    } else {
      chat.sendPropertyMessage(widget.propertyId!, text);
    }

    msgController.clear();
  }

  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}