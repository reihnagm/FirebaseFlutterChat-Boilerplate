import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';

class UserProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;
  final NavigationService navigationService;

  List<ChatUser>? users;
  StreamSubscription? usersStream;
  List<ChatUser>? _selectedUsers;
  List<ChatUser> get selectedUsers => [..._selectedUsers!];

  UserProvider({required this.authenticationProvider, required this.databaseService, required this.navigationService}) {
    _selectedUsers = [];
    getUsers();
  }

  @override
  void dispose() {
    usersStream!.cancel();
    super.dispose();
  }
  
  void getUsers({String? name}) async {
    try {
      usersStream = databaseService.getUsers(name: name).listen((event) async {
        users = event.docs.map((d) {
          Map<String, dynamic> data = d.data() as Map<String, dynamic>;
          data["uid"] = d.id;
          return ChatUser.fromJson(data);
        })
        .where((el) => el.uid != authenticationProvider.auth.currentUser!.uid)
        .toList();
        Future.delayed(Duration.zero, () =>   notifyListeners());
      });
    } catch(e) {  
      debugPrint("Error getting users.");
      debugPrint(e.toString());
    }
  }

  void updateSelectedUsers(ChatUser user) {
    if(_selectedUsers!.contains(user)) {
      _selectedUsers!.remove(user);
    } else {
      _selectedUsers!.add(user);
    }
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void createChat(BuildContext context) async {
    try { 
      List<String> membersIds = _selectedUsers!.map((user) => user.uid!).toList();
      membersIds.add(authenticationProvider.auth.currentUser!.uid);
      bool isGroup = selectedUsers.length > 1;
      // DocumentReference? doc = await databaseService.createChat(
      //   {
      //     "is_group": isGroup,
      //     "is_activity": false,
      //     "members": membersIds, 
      //   }
      // );
      List<ChatUser> members = [];
      for (var uid in membersIds) {
        DocumentSnapshot<Object?> event = await databaseService.getUser(uid)!;
        Map<String, dynamic> userData = event.data() as Map<String, dynamic>;
        userData["uid"] = event.id;
        members.add(ChatUser.fromJson(userData));
      }
      ChatPage chatPage = ChatPage(
        chat: Chat(
          uid: "",
          //  doc!.id
          currentUserId: authenticationProvider.auth.currentUser!.uid,
          reads: [],
          messages: [],
          activity: false,
          members: members,
          group: isGroup,
        )
      );
      _selectedUsers = [];
      Future.delayed(Duration.zero, () => notifyListeners());
      NavigationService.pushNav(context, chatPage);
    } catch(e) {
      debugPrint("Error creating chat.");
      debugPrint(e.toString());
    }
  }
}