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

class GroupData {
  final String name;
  final String? image;

  GroupData({
    required this.name,
    required this.image
  });

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      name: json["name"],
      image: json["image"]
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "image": image,
    };
  }
}

class Chat {
  final String uid;
  final String currentUserId;
  final bool activity;
  final bool group;
  final GroupData groupData;
  final List<ChatUser> members;
  final List<ChatMessage> messages; 
  List<ChatCountRead> readers;
  late final List<ChatUser> recepients;

  Chat({
    required this.uid,
    required this.currentUserId,
    required this.activity,
    required this.group,
    required this.groupData,
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
  String title() => !group ? recepients.first.name! : groupData.name;
  String subtitle() => !group ? isUsersOnline() ? "ONLINE" : "OFFLINE" : recepients.map((user) => user.name!).join(", ");
  String image() => !group ? recepients.first.image! : groupData.image == "" ? "https://www.iconpacks.net/icons/1/free-user-group-icon-296-thumb.png" : groupData.image!;
}