import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';

enum ChatsStatus { idle, loading, loaded, empty, error }
enum MembersStatus { idle, loading, loaded, empty, error }
enum TokensStatus { idle, loading, loaded, empty, error }

class ChatsProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;

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
    required this.sharedPreferences,
    required this.authenticationProvider,
    required this.databaseService
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
      chatsStream = databaseService.getChatsForUser(userId: authenticationProvider.userId())!.listen((snapshot) async {
        chats = await Future.wait(snapshot.docs.map((doc) async {
          Map<String, dynamic> chatData = doc.data() as Map<String, dynamic>;
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
        
          QuerySnapshot<Object?>? readerCountIds = await databaseService.readerCountIds(
            chatId: doc.id, 
            userId: authenticationProvider.userId()
          );

          if(readerCountIds!.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in readerCountIds.docs) {
              Map<String, dynamic> readerDataCount = item.data() as Map<String, dynamic>;
              List readerCountIds = readerDataCount["readerCountIds"];
              for (var readerCountId in readerCountIds) {
                messagesGroupCount.add(readerCountId);
              }
            }
          }
          
          QuerySnapshot<Object?>? messageCount = await databaseService.getMessageCountForChat(chatId: doc.id);
          if(messageCount!.docs.isNotEmpty) {
            for (QueryDocumentSnapshot<Object?> item in messageCount.docs) {
              Map<String, dynamic> messageDataCount = item.data() as Map<String, dynamic>;
              ChatMessage message = ChatMessage.fromJSON(messageDataCount);
              messagesPersonalCount.add(message);
            }
          }
          QuerySnapshot<Object?>? lastMessage = await databaseService.getLastMessageForChat(chatId: doc.id);
          if(lastMessage!.docs.isNotEmpty) {
            Map<String, dynamic> messageData = lastMessage.docs.first.data() as Map<String, dynamic>;
            ChatMessage message = ChatMessage.fromJSON(messageData);
            messages.add(message);
          } 
          return Chat(
            uid: doc.id, 
            currentUserId: authenticationProvider.userId(), 
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

  void getMembersByChat() async {
    try {
      membersStream = databaseService.getMembersChat(chatId: chatId())!.listen((snapshot) {
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
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  void getTokensByChat() {
    try {
      tokensStream = databaseService.getTokensChat(chatId: chatId())!.listen((snapshot) {
        if(snapshot.exists) {
          Map<String, dynamic> item = snapshot.data() as Map<String, dynamic>; 
          List<Token> tokensAssign = [];
          List tokensList = item["tokens"];
          for (var tokenList in tokensList) {
            tokensAssign.add(Token.fromJson(tokenList));
          }
          _tokens = tokensAssign;
          setStateTokensStatus(TokensStatus.loaded);
        }
      });
    } catch(e) {
      debugPrint(e.toString());
    }
  }


  Future<void> deleteChat({required String chatId}) async {
    try {
      await databaseService.deleteChat(chatId: chatId);
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  String chatId() => sharedPreferences.getString("chatId") ?? "";

}