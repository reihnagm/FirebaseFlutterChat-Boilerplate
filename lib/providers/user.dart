import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:uuid/uuid.dart';

enum CreateGroupStatus { idle, loading, loaded, empty, error }

class UserProvider extends ChangeNotifier {
  final AuthenticationProvider authenticationProvider;
  final DatabaseService databaseService;
  final NavigationService navigationService;
  final CloudStorageService cloudStorageService;

  CreateGroupStatus _createGroupStatus = CreateGroupStatus.idle;
  CreateGroupStatus get createGroupStatus => _createGroupStatus;

  List<ChatUser>? _users;
  List<ChatUser>? get users {
    if(_users != null) {
      return _users!.where((el) => el.uid != authenticationProvider.userUid()).toList();
    }
    return null;
  }
  StreamSubscription? usersStream;
  List<ChatUser> selectedUsers = [];

  UserProvider({
    required this.authenticationProvider, 
    required this.databaseService, 
    required this.navigationService,
    required this.cloudStorageService  
  });

  void setStateCreateGroupStatus(CreateGroupStatus createGroupStatus) {
    _createGroupStatus = createGroupStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  @override
  void dispose() {
    usersStream!.cancel();
    super.dispose();
  }
  
  void getUsers({String? name}) async {
    try {
      usersStream = databaseService.getUsers(name: name).listen((event) async {
        _users = event.docs.map((d) {
          Map<String, dynamic> data = d.data() as Map<String, dynamic>;
          data["uid"] = d.id;
          return ChatUser.fromJson(data);
        }).toList();
        Future.delayed(Duration.zero, () => notifyListeners());
      });
    } catch(e) {  
      debugPrint(e.toString());
    }
  }

  void updateSelectedUsers(ChatUser user) {
    if(selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  Future<void> createChat(BuildContext context, {
    required String groupName,
    PlatformFile? groupImage,
  }) async {
    List<String> relations = selectedUsers.map((user) => user.uid!).toSet().toList();
    relations.add(authenticationProvider.userUid());
    bool isGroup = selectedUsers.length > 1;
    if(isGroup) {
      String chatId = const Uuid().v4();
      List<dynamic> tokens = [];
      List<dynamic> isActivity = [];
      List<dynamic> members = [];
      setStateCreateGroupStatus(CreateGroupStatus.loading);
      for (String uid in relations) {
        try {
          DocumentSnapshot<Object?> snapshot = await databaseService.getUser(uid)!;
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          members.add({
            "uid": snapshot.id,
            "token": userData["token"],
            "name": userData["name"],
            "email": userData["email"],
            "image": userData["image"],
            "isOnline":  userData["isOnline"],
            "last_active": userData["last_active"]
          });
          tokens.add({
            "userUid": snapshot.id,
            "token": userData["token"]
          });
          isActivity.add({
            "chat_id": chatId,
            "user_id": snapshot.id,
            "name": userData["name"],
            "is_active": false,
            "is_group": true
          });
        } catch(e) {
          setStateCreateGroupStatus(CreateGroupStatus.error);
          debugPrint(e.toString());
        }
      }
      try {
        String? groupImageUrl = "";
        if(groupImage != null) {
          groupImageUrl = await cloudStorageService.saveGroupImageToStorage(
            groupName: groupName, 
            groupImage: groupImage
          );
        }
        try {
          await databaseService.createChatGroup(chatId, {
            "is_group": isGroup,
            "is_activity": isActivity,
            "group": {
              "name": groupName,
              "image": groupImageUrl,
              "tokens": FieldValue.arrayUnion(tokens)
            },  
            "members": members,
            "relations": relations,
            "created_at": DateTime.now(),
            "updated_at": DateTime.now(),
          });
          Navigator.of(context).pop();
          setStateCreateGroupStatus(CreateGroupStatus.loaded);
        } catch(e) {
          setStateCreateGroupStatus(CreateGroupStatus.error);
          debugPrint(e.toString());
        }
      } catch(e) {
        setStateCreateGroupStatus(CreateGroupStatus.error);
        debugPrint(e.toString());
      }
    }
  }
}