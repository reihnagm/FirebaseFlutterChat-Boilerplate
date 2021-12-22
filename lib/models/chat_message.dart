import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  unknown
}

class ChatMessage {
  final String content;
  final String senderID;
  final bool isRead;
  final MessageType type;
  final DateTime sentTime;  

  ChatMessage({
    required this.content,
    required this.senderID,
    required this.isRead,
    required this.type,
    required this.sentTime
  });

  factory ChatMessage.fromJSON(Map<String, dynamic> data) {
    MessageType messageType;
    switch (data["type"]) {
      case "text":
        messageType = MessageType.text;
      break;
      case "image": 
        messageType = MessageType.image;
      break;
      default:
        messageType = MessageType.unknown;
    }
    return ChatMessage(
      content: data["content"], 
      senderID: data["sender_id"], 
      isRead: data["is_read"],
      type: messageType, 
      sentTime: data["sent_time"].toDate()
    );
  }
  Map<String, dynamic> toJson() {
    String messageType;
    switch (type) {
      case MessageType.text: 
        messageType = "text";
      break;
      case MessageType.image:
        messageType = "image";
      break;
      default:
        messageType = "";
    }
    return {
      "content": content,
      "type": messageType,
      "sender_id": senderID,
      "is_read": isRead,
      "sent_time": Timestamp.fromDate(sentTime)
    };
  }
}