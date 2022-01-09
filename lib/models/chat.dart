import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';

class ChatBadgeCount {
  final String chatId;
  final String messageId;
  final String readerId;
  final bool isRead;

  ChatBadgeCount({
    required this.chatId,
    required this.messageId,
    required this.readerId,
    required this.isRead,
  });

  factory ChatBadgeCount.fromJson(Map<String, dynamic> json) {
    return ChatBadgeCount(
      chatId: json["chat_id"],
      messageId: json["message_id"],
      readerId: json["reader_id"], 
      isRead: json["is_read"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "chat_id": chatId,
      "message_id": messageId,
      "reader_id": readerId,
      "is_read": isRead,
    };
  }
}

class GroupData {
  final String name;
  final String image;
  final List<Token> tokens;

  GroupData({
    required this.name,
    required this.image,
    required this.tokens
  });

  factory GroupData.fromJson(Map<String, dynamic> json) {
    return GroupData(
      name: json["name"],
      image: json["image"],
      tokens: List<Token>.from(json["tokens"].map((x) => Token.fromJson(x)))
    );
  }
}


class Token {
  Token({
    required this.userUid,
    required this.token,
  });

  String userUid;
  String token;

  factory Token.fromJson(Map<String, dynamic> json) => Token(
    userUid: json["userUid"],
    token: json["token"],
  );
}

class Chat {
  final String uid;
  final String currentUserId;
  final bool activity;
  final bool group;
  final GroupData groupData;
  late final List<ChatUser> members;
  final List<ChatMessage> messages; 
  final List<dynamic> messagesGroupCount;
  final List<ChatMessage> messagesPersonalCount; 
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
    required this.messagesGroupCount,
    required this.messagesPersonalCount
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
  }

  int readCount() => messagesPersonalCount.isEmpty 
  ? 0 
  : group 
  ? messagesGroupCount.fold(0, (previousValue, element) => element + previousValue)
  : messagesPersonalCount.where((el) => el.isRead == false && el.receiverId == currentUserId).toList().length;
  bool isRead() => messages.any((m) => m.isRead);

  bool isUsersOnline() => recepients.any((el) => el.isUserOnline());
  String title() => !group ? recepients.first.name! : groupData.name;
  String subtitle() => !group ? isUsersOnline() ? "ONLINE" : "OFFLINE" : peopleJoinGroup.map((user) => user.name!).join(", ");
  String image() => !group ? recepients.first.image! : groupData.image == "" ? "https://www.iconpacks.net/icons/1/free-user-group-icon-296-thumb.png" : groupData.image;
}