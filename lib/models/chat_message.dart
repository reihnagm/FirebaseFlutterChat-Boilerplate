import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  unknown
}

class ChatMessage {
  final String uid;
  final String content;
  final String senderId;
  final String senderName;
  final String receiverId;
  final bool isRead;
  final bool softDelete;
  final MessageType type;
  final DateTime sentTime;  
  final List<Readers> readers;
  final List<String> readerCountIds;

  ChatMessage({
    required this.uid,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.isRead,
    required this.softDelete,
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
      uid: data["uid"],
      content: data["content"], 
      type: messageType, 
      senderId: data["sender_id"],
      senderName: data["sender_name"],
      receiverId: data["receiver_id"], 
      isRead: data["is_read"],
      softDelete: data["soft_delete"],
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
      "uid": uid,
      "content": content,
      "type": messageType,
      "sender_id": senderId,
      "sender_name": senderName,
      "receiver_id": receiverId,
      "is_read": isRead,
      "soft_delete": softDelete,
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
  final DateTime createdAt;

  Readers({
    required this.uid,
    required this.name,
    required this.image,
    required this.isRead,
    required this.seen,
    required this.createdAt
  });

  factory Readers.fromJson(Map<String, dynamic> json) {
    return Readers(
      uid: json["uid"], 
      name: json["name"],
      image: json["image"], 
      isRead: json["is_read"],
      seen: json["seen"].toDate(),
      createdAt: json["created_at"].toDate()
    );
  }
}