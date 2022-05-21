import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:chat/services/cloud_storage.dart';
import 'package:chat/models/chat_user.dart';
import 'package:chat/providers/authentication.dart';
import 'package:chat/services/database.dart';
import 'package:chat/services/navigation.dart';

enum CreateGroupStatus { idle, loading, loaded, empty, error }

class UserProvider extends ChangeNotifier {
  final AuthenticationProvider ap;
  final DatabaseService ds;
  final NavigationService ns;
  final CloudStorageService css;

  CreateGroupStatus _createGroupStatus = CreateGroupStatus.idle;
  CreateGroupStatus get createGroupStatus => _createGroupStatus;

  List<ChatUser>? _users;
  List<ChatUser>? get users {
    if(_users != null) {
      return _users!.where((el) => el.uid != ap.userId()).toList();
    }
    return null;
  }
  StreamSubscription? usersStream;
  List<ChatUser> selectedUsers = [];

  UserProvider({
    required this.ap, 
    required this.ds, 
    required this.ns,
    required this.css  
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
  
  void getUsers({String? name}) {
    usersStream = ds.getUsers(name: name).listen((event) async {
      _users = event.docs.map((d) {
        Map<String, dynamic> data = d.data() as Map<String, dynamic>;
        data["uid"] = d.id;
        return ChatUser.fromJson(data);
      }).toList();
      Future.delayed(Duration.zero, () => notifyListeners());
    });
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
    relations.add(ap.userId());
    bool isGroup = selectedUsers.length > 1;
    if(isGroup) {
      String chatId = const Uuid().v4();
      List tokens = [];
      List isActivity = [];
      List members = [];
      List onScreens = [];
      setStateCreateGroupStatus(CreateGroupStatus.loading);

      for (String uid in relations) {
        try {
          await Future.wait([
            ds.getUser(userId: uid).then((DocumentSnapshot<Object?> snapshot) async {
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
                "user_id": snapshot.id,
                "token": userData["token"]
              });
              isActivity.add({
                "chat_id": chatId,
                "user_id": snapshot.id,
                "name": userData["name"],
                "is_active": false,
                "is_group": true
              });
              onScreens.add({
                "user_id": snapshot.id,
                "token": userData["token"],
                "on": false 
              });
              
              String? groupImageUrl = "";
              if(groupImage != null) {
                groupImageUrl = await css.saveGroupImageToStorage(
                  groupName: groupName, 
                  groupImage: groupImage
                );
              }
              await ds.createChatGroup(chatId, {
                "is_group": isGroup,
                "is_activity": isActivity,
                "group": {
                  "name": groupName,
                  "image": groupImageUrl,
                },  
                "members": members,
                "relations": relations,
                "created_at": DateTime.now(),
                "updated_at": DateTime.now(),
              });
            }),
            ds.createOnScreens(chatId, {
              "id": chatId,
              "on_screens": onScreens,
            }),
            ds.insertTokens(
              chatId: chatId, 
              data: {
                "tokens": tokens,
              }
            ),
            ds.insertMembers(
              chatId: chatId, 
              data: {
                "members": members
              }
            )
          ]);
          ns.goBack(context);
          setStateCreateGroupStatus(CreateGroupStatus.loaded);
        } catch(e, stacktrace) {
          debugPrint(stacktrace.toString());
        }
      }
    }
  }
  
}