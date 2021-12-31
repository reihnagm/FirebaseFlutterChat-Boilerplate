import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';

class ChatsProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;

  List<Chat>? chats;
  StreamSubscription? chatsStream;
  ChatsProvider({
    required this.authenticationProvider,
    required this.databaseService
  });

  @override 
  void dispose() {
    chatsStream!.cancel();
    super.dispose();
  }

  Future<void> getChats() async {
    try {
      chatsStream = databaseService.getChatsForUser(authenticationProvider.auth.currentUser!.uid).listen((snapshot) async {
        chats = await Future.wait(snapshot.docs.map((d) async {
          Map<String, dynamic> chatData = d.data() as Map<String, dynamic>;
          List<ChatUser> members = [];
          for (Map<String, dynamic> member in chatData["members"]) {
            Map<String, dynamic> userData = member;
            userData["uid"] = member["uid"];
            members.add(ChatUser.fromJson(userData));
          }
          List<ChatCountRead> readers = [];
          for (Map<String, dynamic> item in chatData["readers"]) {
            Map<String, dynamic> reader = item;
            readers.add(ChatCountRead.fromJson(reader));
          }
          List<ChatMessage> messages = [];
          QuerySnapshot chatMessage = await databaseService.getLastMessageForChat(d.id);
          if(chatMessage.docs.isNotEmpty) {
            Map<String, dynamic> messageData = chatMessage.docs.first.data() as Map<String, dynamic>;
            ChatMessage message = ChatMessage.fromJSON(messageData);
            messages.add(message);
          }
          return Chat(
            uid: d.id, 
            currentUserId: authenticationProvider.auth.currentUser!.uid, 
            activity: chatData["is_activity"], 
            group: chatData["is_group"], 
            members: members, 
            readers: readers,
            messages: messages, 
          );
        }).toList());
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}