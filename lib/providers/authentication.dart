import 'dart:async';

import 'package:chatv28/providers/chats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/src/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatv28/services/cloud_storage.dart';
import 'package:chatv28/pages/login.dart';
import 'package:chatv28/pages/home.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/services/database.dart';

enum AuthStatus { idle, loading, loaded, empty, error }
enum LoginStatus { idle, loading, loaded, empty, error }
enum RegisterStatus { idle, loading, loaded, empty, error }
enum LogoutStatus { idle, loading, loaded, empty, error }

class AuthenticationProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  final DatabaseService databaseService;
  final CloudStorageService cloudStorageService;

  AuthStatus _authStatus = AuthStatus.loading;
  AuthStatus get authStatus => _authStatus;

  LoginStatus _loginStatus = LoginStatus.idle;
  LoginStatus get loginStatus => _loginStatus;

  RegisterStatus _registerStatus = RegisterStatus.idle;
  RegisterStatus get registerStatus => _registerStatus;

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

  void setStateRegisterStatus(RegisterStatus registerStatus) {
    _registerStatus = registerStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  void setStateLogoutStatus(LogoutStatus logoutStatus) {
    _logoutStatus = logoutStatus;
    Future.delayed(Duration.zero, () => notifyListeners());
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  ChatUser? chatUser;
  
  AuthenticationProvider({
    required this.sharedPreferences, 
    required this.databaseService,
    required this.cloudStorageService
  });

  Future<void> initAuthStateChanges() async {
    try {
      DocumentSnapshot<Object?> snapshot = await databaseService.getUser(userId())!;
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      chatUser = ChatUser.fromJson({
        "uid": userId(),
        "name": userData["name"],
        "email": userData["email"],
        "last_active": userData["last_active"],
        "isOnline": userData["isOnline"],
        "image": userData["image"],
        "token": userData["token"]
      });  
      await databaseService.updateUserOnlineToken(userId(), true);
      sharedPreferences.setString("userName", userData["name"]);
      setStateAuthStatus(AuthStatus.loaded);
    } catch(e) {
      setStateAuthStatus(AuthStatus.error);
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    setStateLogoutStatus(LogoutStatus.loading);
    try {
      await databaseService.updateUserOnlineToken(userId(), false);
      try {
        await auth.signOut();
        sharedPreferences.clear();
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
      sharedPreferences.setString("userId", auth.currentUser!.uid);
      await databaseService.updateUserOnlineToken(userId(), true);
      setStateLoginStatus(LoginStatus.loaded);
      NavigationService().pushNavReplacement(context, const HomePage(currentPage: 0));   
    } on FirebaseAuthException {
      setStateLoginStatus(LoginStatus.error);
    } catch(e) {
      setStateLoginStatus(LoginStatus.error);
      debugPrint(e.toString());
    }
  } 

  Future<void> registerUsingEmailAndPassword(BuildContext context, String name, String email, String password, PlatformFile image) async {
    try {
      setStateRegisterStatus(RegisterStatus.loading);
      await auth.createUserWithEmailAndPassword(email: email, password: password);
      String? imageUrl = await cloudStorageService.saveUserImageToStorage(auth.currentUser!.uid, image);
      await databaseService.register(auth.currentUser!.uid, name, email, imageUrl!);
      sharedPreferences.setBool("login", true);
      sharedPreferences.setString("userId", auth.currentUser!.uid);
      setStateRegisterStatus(RegisterStatus.loaded);
      NavigationService().pushNavReplacement(context, const HomePage(currentPage: 0)); 
    } on FirebaseException {
      setStateRegisterStatus(RegisterStatus.error);
    } catch(e) {
      setStateRegisterStatus(RegisterStatus.error);
      debugPrint(e.toString());
    }
  }

  bool isLogin() => sharedPreferences.getBool("login") ?? false;
  String userId() => sharedPreferences.getString("userId") ?? "";
  String userName() => sharedPreferences.getString("userName") ?? "";
  String userImage() => sharedPreferences.getString("userImage") ?? "";
}