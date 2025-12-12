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
    final theme = Theme.of(context);
    final isPropertyChat = widget.propertyId != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isPropertyChat ? "Ask About Property" : "Support Chat",
        ),
      ),

      body: Column(
        children: [
          /// PROPERTY CONTEXT
          if (isPropertyChat)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.home, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You’re chatting about this property",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          /// MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: isPropertyChat
                  ? chat.getPropertyMessages(widget.propertyId!)
                  : chat.getSupportMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isNotEmpty) {
                  final lastSender = docs.last["senderId"];
                  agentTyping = lastSender == "agent_bot";
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isMe = data["senderId"] == chat.user!.uid;

                    return _chatBubble(
                      context: context,
                      text: data["text"],
                      timestamp: data["timestamp"],
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          /// TYPING INDICATOR
          if (agentTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6),
              child: Row(
                children: const [
                  Text(
                    "Agent is typing…",
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),

          /// INPUT BAR
          _messageInput(theme),
        ],
      ),
    );
  }

  /// CHAT BUBBLE
  Widget _chatBubble({
    required BuildContext context,
    required String text,
    required Timestamp timestamp,
    required bool isMe,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  color: Colors.black.withOpacity(0.08),
                )
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(timestamp),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// INPUT BAR
  Widget _messageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -2),
            color: Colors.black.withOpacity(0.12),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: msgController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              decoration: InputDecoration(
                hintText: "Message the agent…",
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// SEND MESSAGE
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

  /// FORMAT TIME
  String _formatTime(Timestamp ts) {
    final dt = ts.toDate();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}