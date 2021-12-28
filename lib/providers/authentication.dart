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

enum LoginStatus { idle, loading, loaded, empty, error }

class AuthenticationProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  final DatabaseService databaseService;

  LoginStatus _loginStatus = LoginStatus.idle;
  LoginStatus get loginStatus => _loginStatus;

  void setStateLoginStatus(LoginStatus loginStatus) {
    _loginStatus = loginStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  late ChatUser chatUser;
  
  AuthenticationProvider({required this.sharedPreferences, required this.databaseService}) {
    initAuthStateChanges(); 
  }

  Future<void> initAuthStateChanges() async {
    try {
      DocumentSnapshot<Object?> event = await databaseService.getUser(auth.currentUser!.uid)!;
      databaseService.updateUserLastSeenTime(auth.currentUser!.uid);
      databaseService.updateUserOnline(auth.currentUser!.uid, true);
      Map<String, dynamic> userData = event.data() as Map<String, dynamic>;
      chatUser = ChatUser.fromJson({
        "uid": auth.currentUser!.uid,
        "name": userData["name"],
        "email": userData["email"],
        "last_active": userData["last_active"],
        "isOnline": userData["isOnline"],
        "image": userData["image"],
        "token": await FirebaseMessaging.instance.getToken()
      }); 
      Future.delayed(Duration.zero, () => notifyListeners());
    } catch(e) {
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    await databaseService.setRelationUserOnline(auth.currentUser!.uid, false);
    await databaseService.updateUserOnline(auth.currentUser!.uid, false);
    NavigationService.pushNavReplacement(context, const LoginPage());
    await auth.signOut();
  }

  Future<void> loginUsingEmailAndPassword(BuildContext context, String email, String password) async {
    setStateLoginStatus(LoginStatus.loading);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await databaseService.updateUserToken(auth.currentUser!.uid, await FirebaseMessaging.instance.getToken());
      await databaseService.setRelationUserOnline(auth.currentUser!.uid, true);
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