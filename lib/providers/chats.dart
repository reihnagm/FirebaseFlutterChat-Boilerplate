import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';

enum ChatsStatus { idle, loading, loaded, empty, error }

class ChatsProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;

  ChatsProvider({
    required this.authenticationProvider,
    required this.databaseService
  });

  ChatsStatus _chatsStatus = ChatsStatus.loading;
  ChatsStatus get chatsStatus => _chatsStatus;

  void setStateChatsStatus(ChatsStatus chatsStatus) {
    _chatsStatus = chatsStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  List<Chat>? chats;
  StreamSubscription? chatsStream;
  
  @override 
  void dispose() {
    chatsStream!.cancel();
    super.dispose();
  }

  void getChats() {
    try {
      chatsStream = databaseService.getChatsForUser(authenticationProvider.userUid())!.listen((snapshot) async {
        chats = await Future.wait(snapshot.docs.map((doc) async {
          Map<String, dynamic> chatData = doc.data() as Map<String, dynamic>;
          List<dynamic> m = chatData["members"];
          List<dynamic> r = chatData["readers"];
          GroupData groupData = GroupData.fromJson(chatData["group"]);
          // DocumentSnapshot<Object?> snapshot = await databaseService.getUser(authenticationProvider.userUid())!;
          // Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          List<ChatUser> members = [];
          if(m.isNotEmpty) {
            for (var member in m) {
              members.add(ChatUser.fromJson(member));
            }
          }
          List<ChatCountRead> readers = [];
          if(r.isNotEmpty) {
            for (var reader in r) {
              readers.add(ChatCountRead.fromJson(reader));
            }
          }
          // Optional 2
          // List<dynamic>? membersChat = await databaseService.getMembersChat(doc.id);
          // if(membersChat!.isNotEmpty) {
          //   for (var item in membersChat) {
          //     members.add(ChatUser.fromJson(item));
          //   }
          // }
          
           // Optional 2
          // List<dynamic>? readersChat = await databaseService.getReadersChat(doc.id);
          // if(readersChat.isNotEmpty) {
          //   for (var item in readersChat) {
          //     readers.add(ChatCountRead.fromJson(item));
          //   }
          // }
          List<ChatMessage> messages = [];
          try {
            QuerySnapshot<Object?>? chatMessage = await databaseService.getLastMessageForChat(doc.id);
            if(chatMessage!.docs.isNotEmpty) {
              Map<String, dynamic> messageData = chatMessage.docs.first.data() as Map<String, dynamic>;
              ChatMessage message = ChatMessage.fromJSON(messageData);
              messages.add(message);
            } // Prevent Bad State No Element
          } catch(e) {
            debugPrint(e.toString());
          }
          return Chat(
            uid: doc.id, 
            currentUserId: authenticationProvider.userUid(), 
            activity: chatData["is_activity"], 
            group: chatData["is_group"], 
            groupData: GroupData(
              image: groupData.image,
              name: groupData.name
            ),
            members: members,
            readers: readers,
            messages: messages, 
          );
        }).toList());
        setStateChatsStatus(ChatsStatus.loaded);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}