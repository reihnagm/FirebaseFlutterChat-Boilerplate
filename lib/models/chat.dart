import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';

class ChatCountReadSees {
  final Timestamp id;
  final String messageId;
  final String uid;

  ChatCountReadSees({
    required this.id,
    required this.messageId,
    required this.uid,
  });

  factory ChatCountReadSees.fromJson(Map<String, dynamic> json) {
    return ChatCountReadSees(
      id: json["id"],
      messageId: json["message_id"],
      uid: json["uid"], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "message_id": messageId,
      "uid": uid,
    };
  }
}

class ChatCountRead {
  final String messageId;
  final String readerId;
  final bool isRead;

  ChatCountRead({
    required this.messageId,
    required this.readerId,
    required this.isRead,
  });

  factory ChatCountRead.fromJson(Map<String, dynamic> json) {
    return ChatCountRead(
      messageId: json["message_id"],
      readerId: json["reader_id"], 
      isRead: json["is_read"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message_id": messageId,
      "reader_id": readerId,
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
  late final List<ChatUser> members;
  final List<ChatMessage> messages; 
  List<ChatCountRead> readers;
  late final List<ChatUser> peopleJoinGroup;
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
  
    List<ChatUser> chatUserAssign = [];
    for (ChatUser chatUser in members) {
      chatUserAssign.add(ChatUser(
        uid: chatUser.uid,
        email: chatUser.email,
        image: chatUser.image,
        isOnline: chatUser.isOnline,
        name: chatUser.uid == currentUserId ? "You" : chatUser.name,
        lastActive: chatUser.lastActive,
        token: chatUser.token,
      )); 
    }
    peopleJoinGroup = chatUserAssign;
    readers = readers.where((el) => el.isRead == false && el.readerId == currentUserId).toList();
  }
 
  int readCount() => readers.length;
  bool isRead() => messages.any((m) => m.isRead);

  bool isUsersOnline() => recepients.any((el) => el.isUserOnline());
  String title() => !group ? recepients.first.name! : groupData.name;
  String subtitle() => !group ? isUsersOnline() ? "ONLINE" : "OFFLINE" : peopleJoinGroup.map((user) => user.name!).join(", ");
  String image() => !group ? recepients.first.image! : groupData.image == "" ? "https://www.iconpacks.net/icons/1/free-user-group-icon-296-thumb.png" : groupData.image!;
}