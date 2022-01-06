import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';

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
  List<ChatUser>? _selectedUsers;
  List<ChatUser> get selectedUsers => [..._selectedUsers!];

  UserProvider({
    required this.authenticationProvider, 
    required this.databaseService, 
    required this.navigationService,
    required this.cloudStorageService  
  }) {
    _selectedUsers = [];
  }

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
        Future.delayed(Duration.zero, () =>   notifyListeners());
      });
    } catch(e) {  
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

  Future<void> createChat(BuildContext context, {
    required String groupName,
    PlatformFile? groupImage,
  }) async {
    List<String> relations = _selectedUsers!.map((user) => user.uid!).toList();
    relations.add(authenticationProvider.userUid());
    bool isGroup = selectedUsers.length > 1;
    if(isGroup) {
      List<Map<String, dynamic>> members = [];
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
            "imageUrl": userData["image"],
            "isOnline": false,
            "last_active": userData["last_active"]
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
          await databaseService.createChat({
            "is_group": isGroup,
            "is_activity": false,
            "group": {
              "name": groupName,
              "image": groupImageUrl
            },  
            "members": members,
            "readers": [],
            "relations": relations,
          });
          Navigator.of(context).pop();
          setStateCreateGroupStatus(CreateGroupStatus.loaded);
        } catch(e) {
          debugPrint(e.toString());
        }
      } catch(e) {
        debugPrint(e.toString());
      }
    }
  }
}