import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';

class ChatCountRead {
  final String messageId;
  final String receiverId;
  final bool isRead;

  ChatCountRead({
    required this.messageId,
    required this.receiverId,
    required this.isRead
  });

  factory ChatCountRead.fromJson(Map<String, dynamic> json) {
    return ChatCountRead(
      messageId: json["message_id"],
      receiverId: json["receiver_id"], 
      isRead: json["is_read"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message_id": messageId,
      "receiver_id": receiverId,
      "is_read": isRead,
    };
  }

}

class Chat {
  final String uid;
  final String currentUserId;
  final bool activity;
  final bool group;
  final List<ChatUser> members;
  final List<ChatMessage> messages; 
  List<ChatCountRead> readers;
  late final List<ChatUser> recepients;

  Chat({
    required this.uid,
    required this.currentUserId,
    required this.activity,
    required this.group,
    required this.members,
    required this.messages,
    required this.readers,
  }) {
    recepients = members.where((el) => el.uid != currentUserId).toList();
    readers = readers.where((el) => el.isRead == false && el.receiverId == currentUserId).toList();
  }

  List<ChatUser> fetchListRecepients() {
    return recepients;
  }
 
  int readCount() => readers.length;
  bool isRead() => readers.isEmpty ? true : false;

  bool isUsersOnline() => fetchListRecepients().any((el) => el.isUserOnline());
  String title() => !group ? recepients.first.name! : recepients.map((user) => user.name!).join(", ");
  String imageURL() => !group ? recepients.first.imageUrl! : "https://t4.ftcdn.net/jpg/03/99/12/41/360_F_399124149_L3lTd03yuk7b0lhOhoqbJ0dc6Wjw6WQH.jpg";
}