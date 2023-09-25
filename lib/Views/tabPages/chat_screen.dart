import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String userId;
  final String userName;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  User? currentUser;
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with User'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('senderId', whereIn: [widget.userId, currentUserId])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                // Implement the UI to display the messages here
                // Loop through 'messages' and show each message
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;

                    if (message['senderId'] == currentUserId) {
                      // Sent message by current user
                      final userName = 'Send To: ${message['userName']}';

                      return ListTile(
                        title: Text(message['text']),
                        subtitle: Text(userName),
                      );
                    } else {
                      // Received message by current user
                      final receivedTime =
                          (message['timestamp'] as Timestamp).toDate();
                      final currentTime = DateTime.now();
                      final difference = currentTime.difference(receivedTime);
                      final minutesAgo = difference.inMinutes;
                      final userName = 'Received $minutesAgo minutes ago';

                      return ListTile(
                        title: Text(message['text']),
                        subtitle: Text(userName),
                      );
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Send message to Firestore
                    final messageText = _messageController.text;
                    if (messageText.isNotEmpty) {
                      sendMessage(messageText);
                      _messageController.clear();
                    }
                  },
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage(String messageText) {
    final messageRef = FirebaseFirestore.instance.collection('messages');
    messageRef.add({
      'senderId': widget.currentUserId,
      'receiverId': widget.userId,
      'userName': widget.userName,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
