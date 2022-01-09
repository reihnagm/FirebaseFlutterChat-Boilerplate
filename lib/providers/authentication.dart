import 'dart:async';

import 'package:chatv28/providers/chats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatv28/pages/login.dart';
import 'package:chatv28/pages/home.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/services/database.dart';

enum AuthStatus { idle, loading, loaded, empty, error }
enum LoginStatus { idle, loading, loaded, empty, error }
enum LogoutStatus { idle, loading, loaded, empty, error }

class AuthenticationProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  final DatabaseService databaseService;

  AuthStatus _authStatus = AuthStatus.loading;
  AuthStatus get authStatus => _authStatus;

  LoginStatus _loginStatus = LoginStatus.idle;
  LoginStatus get loginStatus => _loginStatus;

  LogoutStatus _logoutStatus = LogoutStatus.idle;
  LogoutStatus get logoutStatus => _logoutStatus;

  void setStateAuthStatus(AuthStatus authStatus) {
    _authStatus = authStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateLoginStatus(LoginStatus loginStatus) {
    _loginStatus = loginStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateLogoutStatus(LogoutStatus logoutStatus) {
    _logoutStatus = logoutStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  ChatUser? chatUser;
  
  AuthenticationProvider({required this.sharedPreferences, required this.databaseService});

  Future<void> initAuthStateChanges() async {
    try {
      DocumentSnapshot<Object?> snapshot = await databaseService.getUser(userUid())!;
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      try {
        await databaseService.updateUserLastSeenTime(userUid());
      } catch(e) {
        debugPrint(e.toString());
      }
      try {
        await databaseService.updateUserOnline(userUid(), true);
      } catch(e) {
        debugPrint(e.toString());
      }
      try {
        await databaseService.updateUserToken(userUid(), await FirebaseMessaging.instance.getToken());
      } catch(e) {
        debugPrint(e.toString());
      }
      chatUser = ChatUser.fromJson({
        "uid": userUid(),
        "name": userData["name"],
        "email": userData["email"],
        "last_active": userData["last_active"],
        "isOnline": userData["isOnline"],
        "image": userData["image"],
        "token": await FirebaseMessaging.instance.getToken()
      });  
      sharedPreferences.setString("userName", userData["name"]);
      sharedPreferences.setString("userImage", userData["image"]);
      setStateAuthStatus(AuthStatus.loaded);
    } catch(e) {
      setStateAuthStatus(AuthStatus.error);
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    setStateLogoutStatus(LogoutStatus.loading);
    try {
      await databaseService.updateUserOnline(userUid(), false);
      try {
        await auth.signOut();
        sharedPreferences.clear();
        Provider.of<ChatsProvider>(context, listen: false).clearChats();
        setStateLogoutStatus(LogoutStatus.loaded);
        NavigationService().pushBackNavReplacement(context, const LoginPage());
      } catch(e) {
        debugPrint(e.toString());
        setStateLogoutStatus(LogoutStatus.error);
      }
    } catch(e) {
      setStateLogoutStatus(LogoutStatus.error);
      debugPrint(e.toString());
    }
  }

  Future<void> loginUsingEmailAndPassword(BuildContext context, String email, String password) async {
    setStateLoginStatus(LoginStatus.loading);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      sharedPreferences.setBool("login", true);
      sharedPreferences.setString("userUid", auth.currentUser!.uid);
      setStateLoginStatus(LoginStatus.loaded);
      NavigationService().pushNavReplacement(context, const HomePage());   
    } on FirebaseAuthException {
      setStateLoginStatus(LoginStatus.error);
    } catch(e) {
      setStateLoginStatus(LoginStatus.error);
      debugPrint(e.toString());
    }
  } 

  bool isLogin() => sharedPreferences.getBool("login") ?? false;
  String userName() => sharedPreferences.getString("userName") ?? "";
  String userImage() => sharedPreferences.getString("userImage") ?? "";
  String userUid() => sharedPreferences.getString("userUid") ?? "";
}