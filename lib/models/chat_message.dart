import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  unknown
}

class ChatMessage {
  final String content;
  final String senderId;
  final String senderName;
  final String receiverId;
  final bool isRead;
  final MessageType type;
  final DateTime sentTime;  
  final List<Readers> readers;
  final List<String> readerCountIds;

  ChatMessage({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.isRead,
    required this.type,
    required this.sentTime,
    required this.readers,
    required this.readerCountIds
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
      senderId: data["sender_id"],
      senderName: data["sender_name"],
      receiverId: data["receiver_id"], 
      isRead: data["is_read"],
      type: messageType, 
      sentTime: data["sent_time"].toDate(),
      readers: List<Readers>.from(data["readers"].map((x) => Readers.fromJson(x))),
      readerCountIds: List<String>.from(data["readerCountIds"].map((x) => x))
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
      "sender_id": senderId,
      "sender_name": senderName,
      "receiver_id": receiverId,
      "is_read": isRead,
      "sent_time": Timestamp.fromDate(sentTime),
      "readers": readers,
      "readerCountIds": readerCountIds
    };
  }
}

class Readers {
  final String uid;
  final String name;
  final String image;
  final bool isRead;
  final DateTime seen;

  Readers({
    required this.uid,
    required this.name,
    required this.image,
    required this.isRead,
    required this.seen
  });

  factory Readers.fromJson(Map<String, dynamic> json) {
    return Readers(
      uid: json["uid"], 
      name: json["name"],
      image: json["image"], 
      isRead: json["is_read"],
      seen: json["seen"].toDate()
    );
  }
}