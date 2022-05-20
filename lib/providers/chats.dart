import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/models/chat.dart';
import 'package:chat/models/chat_message.dart';
import 'package:chat/models/chat_user.dart';
import 'package:chat/providers/authentication.dart';
import 'package:chat/services/database.dart';

enum ChatsStatus { idle, loading, loaded, empty, error }
enum MembersStatus { idle, loading, loaded, empty, error }
enum TokensStatus { idle, loading, loaded, empty, error }

class ChatsProvider extends ChangeNotifier {
  final SharedPreferences sp;
  final AuthenticationProvider ap;
  final DatabaseService ds;

  ChatsStatus _chatsStatus = ChatsStatus.loading;
  ChatsStatus get chatStatus => _chatsStatus;

  MembersStatus _membersStatus = MembersStatus.loading;
  MembersStatus get memberStatus => _membersStatus;

  TokensStatus _tokensStatus = TokensStatus.loading;
  TokensStatus get tokensStatus => _tokensStatus;

  void setStateChatsStatus(ChatsStatus chatsStatus) {
    _chatsStatus = chatsStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateMembersStatus(MembersStatus membersStatus) {
    _membersStatus = membersStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateTokensStatus(TokensStatus tokensStatus) {
    _tokensStatus = tokensStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }


  @override
  void dispose() {
    super.dispose();
    tokensStream!.cancel();
    chatsStream!.cancel();
    membersStream!.cancel();
  }

  ChatsProvider({
    required this.sp,
    required this.ap,
    required this.ds
  });

  List<Chat>? chats;
  List<ChatUser> _members = [];
  List<ChatUser> get members => [..._members];

  List<Token> _tokens = [];
  List<Token> get tokens => [..._tokens];

  StreamSubscription? tokensStream;
  StreamSubscription? chatsStream;
  StreamSubscription? membersStream;

  void getChats() {
    try {      
      chatsStream = ds.getChatsForUser(userId: ap.userId()).listen((snapshot) async {
        chats = await Future.wait(snapshot.docs.map((doc) async {
          Map<String, dynamic> chatData = doc.data();
          List<ChatUser> members = [];
          List<IsActivity> isActivity = [];
          List<ChatMessage> messagesPersonalCount = [];
          List messagesGroupCount = [];
          List<ChatMessage> messages = [];
          GroupData groupData;

          groupData = GroupData.fromJson(chatData["group"]);

          for (var active in chatData["is_activity"]) {
            isActivity.add(IsActivity.fromJson(active));
          }

          for (var member in chatData["members"]) {
            members.add(ChatUser.fromJson(member));
          }
        
          QuerySnapshot<Object?>? readerCountIds = await ds.readerCountIds(
            chatId: doc.id, 
            userId: ap.userId()
          );

          if(readerCountIds.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in readerCountIds.docs) {
              Map<String, dynamic> readerDataCount = item.data() as Map<String, dynamic>;
              List readerCountIds = readerDataCount["readerCountIds"];
              for (var readerCountId in readerCountIds) {
                messagesGroupCount.add(readerCountId);
              }
            }
          }
          
          QuerySnapshot<Object?>? messageCount = await ds.getMessageCountForChat(chatId: doc.id);
          if(messageCount.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in messageCount.docs) {
              Map<String, dynamic> messageDataCount = item.data() as Map<String, dynamic>;
              ChatMessage message = ChatMessage.fromJSON(messageDataCount);
              messagesPersonalCount.add(message);
            }
          }
          QuerySnapshot<Object?>? lastMessage = await ds.getLastMessageForChat(chatId: doc.id);
          if(lastMessage.docs.isNotEmpty) {
            Map<String, dynamic> messageData = lastMessage.docs.first.data() as Map<String, dynamic>;
            ChatMessage message = ChatMessage.fromJSON(messageData);
            messages.add(message);
          } 
          return Chat(
            uid: doc.id, 
            currentUserId: ap.userId(), 
            activity: isActivity, 
            group: chatData["is_group"], 
            groupData: GroupData(
              image: groupData.image,
              name: groupData.name,
            ),
            members: members,
            messages: messages, 
            messagesPersonalCount: messagesPersonalCount,
            messagesGroupCount: messagesGroupCount,
          );
        }).toList());
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void getMembersByChat() {
    try {
      membersStream = ds.getMembersChat(chatId: chatId()).listen((snapshot) {
        if(snapshot.exists) {
          Map<String, dynamic> item = snapshot.data() as Map<String, dynamic>; 
          List<ChatUser> membersAssign = [];
          List membersList = item["members"];
          for (var memberList in membersList) {
            membersAssign.add(ChatUser.fromJson(memberList));
          }
          _members = membersAssign;
          _members.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
          setStateMembersStatus(MembersStatus.loaded);
        }
      });
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> getTokensByChat() async {
    try {
      DocumentSnapshot? doc = await ds.getTokensChat(chatId: chatId());    
      Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
      List<Token> tokensAssign = [];
      List tokens = item["tokens"];
      for (dynamic token in tokens) {
        tokensAssign.add(Token.fromJson(token));
      }
      _tokens = tokensAssign;
      setStateTokensStatus(TokensStatus.loaded);
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  Future<void> deleteChat({required String chatId}) async {
    try {
      await ds.deleteChat(chatId: chatId);
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
    }
  }

  String chatId() => sp.getString("chatId") ?? "";

}