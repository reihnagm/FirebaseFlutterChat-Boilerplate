import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/services/cloud_storage.dart';
import 'package:chat/services/database.dart';
import 'package:chat/services/navigation.dart';

import 'package:chat/views/screens/auth/login.dart';
import 'package:chat/views/screens/home.dart';

import 'package:chat/models/chat_user.dart';

enum AuthStatus { idle, loading, loaded, empty, error }
enum LoginStatus { idle, loading, loaded, empty, error }
enum RegisterStatus { idle, loading, loaded, empty, error }
enum LogoutStatus { idle, loading, loaded, empty, error }

class AuthenticationProvider extends ChangeNotifier {
  final SharedPreferences sp;
  final DatabaseService ds;
  final CloudStorageService css;
  final NavigationService ns;

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
    required this.sp, 
    required this.ds,
    required this.css,
    required this.ns
  });

  Future<void> initAuthStateChanges() async {
    try {
      DocumentSnapshot<Object?> snapshot = await ds.getUser(userId: userId());
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
      await ds.updateUserOnlineToken(userId(), true);
      sp.setString("userName", userData["name"]);
      sp.setString("userImage", userData["image"]);
      setStateAuthStatus(AuthStatus.loaded);
    } catch(e) {
      setStateAuthStatus(AuthStatus.error);
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {
    setStateLogoutStatus(LogoutStatus.loading);
    try {
      await Future.wait([
        ds.updateUserOnlineToken(userId(), false), 
        auth.signOut()
      ]);
      setStateLogoutStatus(LogoutStatus.loaded);
      sp.clear();
      ns.pushBackNavReplacement(context, const LoginPage());
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
      setStateLogoutStatus(LogoutStatus.error);
    }
  }

  Future<void> loginUsingEmailAndPassword(BuildContext context, String email, String password) async {
    setStateLoginStatus(LoginStatus.loading);
    try {
      await Future.wait([
        auth.signInWithEmailAndPassword(email: email, password: password), 
        ds.updateUserOnlineToken(userId(), true)
      ]);
      setStateLoginStatus(LoginStatus.loaded);
      sp.setBool("login", true);
      sp.setString("userId", auth.currentUser!.uid);
      ns.pushNavReplacement(context, const HomePage(currentPage: 0));   
    } on FirebaseAuthException {
      setStateLoginStatus(LoginStatus.error);
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
      setStateLoginStatus(LoginStatus.error);
    }
  } 

  Future<void> registerUsingEmailAndPassword(BuildContext context, String name, String email, String password, PlatformFile image) async {
    setStateRegisterStatus(RegisterStatus.loading);
    try {
      await Future.wait([
        auth.createUserWithEmailAndPassword(email: email, password: password),
        css.saveUserImageToStorage(
          uid: auth.currentUser!.uid,
          name: name,
          file: image,
          email: email
        )
      ]); 
      setStateRegisterStatus(RegisterStatus.loaded);
      sp.setBool("login", true);
      sp.setString("userId", auth.currentUser!.uid);
      ns.pushNavReplacement(context, const HomePage(currentPage: 0)); 
    } on FirebaseException {
      setStateRegisterStatus(RegisterStatus.error);
    } catch(e, stacktrace) {
      debugPrint(stacktrace.toString());
      setStateRegisterStatus(RegisterStatus.error);
    }
  }

  bool isLogin() => sp.getBool("login") ?? false;
  String userId() => sp.getString("userId") ?? "";
  String userName() => sp.getString("userName") ?? "";
  String userImage() => sp.getString("userImage") ?? "";
}