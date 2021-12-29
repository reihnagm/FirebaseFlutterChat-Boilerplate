import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    setStateAuthStatus(AuthStatus.loading);
    try {
      DocumentSnapshot<Object?> snapshot = await databaseService.getUser(auth.currentUser!.uid)!;
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      await databaseService.updateUserLastSeenTime(auth.currentUser!.uid);
      await databaseService.updateUserOnline(auth.currentUser!.uid, true);
      await databaseService.updateUserToken(auth.currentUser!.uid, await FirebaseMessaging.instance.getToken());
      chatUser = ChatUser.fromJson({
        "uid": auth.currentUser!.uid,
        "name": userData["name"],
        "email": userData["email"],
        "last_active": userData["last_active"],
        "isOnline": userData["isOnline"],
        "image": userData["image"],
        "token": await FirebaseMessaging.instance.getToken()
      });  
      setStateAuthStatus(AuthStatus.loaded);
    } catch(e) {
      setStateAuthStatus(AuthStatus.error);
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    setStateLogoutStatus(LogoutStatus.loading);
    try {
      await databaseService.updateUserOnline(auth.currentUser!.uid, false);
      await auth.signOut();
      setStateLogoutStatus(LogoutStatus.loaded);
      NavigationService.pushBackNavReplacement(context, const LoginPage());
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loginUsingEmailAndPassword(BuildContext context, String email, String password) async {
    setStateLoginStatus(LoginStatus.loading);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      setStateLoginStatus(LoginStatus.loaded);
      NavigationService.pushNavReplacement(context, const HomePage());
    } on FirebaseAuthException {
      setStateLoginStatus(LoginStatus.error);
      debugPrint("Error logging user into Firebase");
    } catch(e) {
      setStateLoginStatus(LoginStatus.error);
      debugPrint(e.toString());
    }
  } 
}