import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/utils/global.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/utils/constant.dart';

class FirebaseProvider with ChangeNotifier {
  final AuthenticationProvider authenticationProvider; 
  final SharedPreferences sharedPreferences;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  FirebaseProvider({
    required this.sharedPreferences,
    required this.authenticationProvider
  });

  AwesomeNotifications awesomeNotifications = AwesomeNotifications(); 

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  void handleMessage(RemoteMessage message) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> data = message.data;
      String chatId = data["chatId"];
      sharedPreferences.setString("chatId", chatId);
      String avatar = data["avatar"];
      String title = data["title"];
      String subtitle = data["subtitle"];
      String groupName = data["groupName"];
      String groupImage = data["groupImage"];
      String isGroup = data["isGroup"];
      String receiverId = data["receiverId"];
      String receiverName = data["receiverName"];
      String receiverImage = data["receiverImage"];
      GlobalVariable.navState.currentState!.push(
        PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return ChatPage(
            avatar: avatar,
            title: title,  
            subtitle: subtitle,
            groupName: groupName,
            groupImage: groupImage,
            isGroup: isGroup == "true" ? true : false,
            currentUserId: authenticationProvider.userId(),
            receiverId: receiverId,
            receiverName: receiverName,
            receiverImage: receiverImage,
            tokens: const [],
            members: const [],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        })
      );
      // db.collection(chatCollection)
      // .doc(chatId).update({
      //   "updated_at": DateTime.now()
      // });
      // Trigger update changes
    }); 
  }

  Future<void> initializeNotification(BuildContext context) async {
    // androidInitializationSettings = const AndroidInitializationSettings('@drawable/ic_notification');
    // iosInitializationSettings = const IOSInitializationSettings();
    // initializationSettings = InitializationSettings(
    //   android: androidInitializationSettings, 
    //   iOS: iosInitializationSettings
    // );
    // await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void listenNotification(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // RemoteNotification notification = message.notification!;
      Map<String, dynamic> data = message.data;
      displayNotification(data);
      handleMessage(message);
    });
  }

  Future<void> displayNotification(Map<String, dynamic> data) async {
    String title = data["title"];
    String body = data["body"];
    String type = data["type"];
    if(type == "image") {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: GlobalVariable.createUniqueId(),
          color: Colors.transparent,
          fullScreenIntent: true,
          wakeUpScreen: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.BigPicture,
          channelKey: 'basic_channel',
          title: title,
          bigPicture: body,
        )
      );
    } else {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: GlobalVariable.createUniqueId(),
          color: Colors.transparent,
          fullScreenIntent: true,
          wakeUpScreen: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.Default,
          channelKey: 'basic_channel',
          title: title,
          body: body
        )
      );
    }
  }

  Future<void> sendNotification({
    required List<Token> tokens,
    required List<String> registrationIds,
    required String token, 
    required String avatar,
    required String title, 
    required String subtitle,
    required String body,
    required String chatId,
    required String receiverId,
    required String receiverName,
    required String receiverImage,
    required String groupName,
    required String groupImage,
    required bool isGroup,
    required String type
  }) async {
    Map<String, dynamic> data = {};
    if(isGroup) {
      data = {
        "registration_ids": registrationIds,
        "priority":"normal",
        "notification": {
          "title": title,
          "body": type == "image" ? body : "${authenticationProvider.userName()} : $body",
          "sound":"default"
        },
        "data": {
          "chatId": chatId,
          "avatar": avatar,
          "title": title,
          "subtitle": subtitle,
          "body": type == "image" ? body : "${authenticationProvider.userName()} : $body",
          "receiverId": receiverId,
          "receiverName": receiverName,
          "receiverImage": receiverImage,
          "groupName": groupName,
          "groupImage": groupImage,
          "isGroup": true,
          "type": type,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
      };
    } else {
      data = {
        "to": token,
        "priority":"normal",
        "notification": {
          "title": title,
          "body": body,
          "sound":"default"
        },
        "data": {
          "chatId": chatId,
          "avatar": avatar,
          "title": authenticationProvider.userName(),
          "subtitle": subtitle,
          "body": body,
          "receiverId": receiverId,
          "receiverName": receiverName,
          "receiverImage": receiverImage,
          "groupName": "",
          "groupImage": "",
          "isGroup": false,
          "type": type,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
      };
    }
    //  "notification": {
    //   "title": title, => Twice Notification onBackgroundMessage
    //   "body": body, => Twice Notification onBackgroundMessage
    //   "sound":"default"
    // },
    // "click_action": "FLUTTER_NOTIFICATION_CLICK" => Mandatory to Redirect Page 
    try { 
      Dio dio = Dio();
      await dio.post("https://fcm.googleapis.com/fcm/send", 
        data: data,
        options: Options(
          headers: {
            "Authorization": "key=${AppConstants.firebaseKey}"
          }
        )
      );
    } on DioError catch(e) {
      debugPrint(e.response!.data.toString());
      debugPrint(e.response!.statusMessage.toString());
      debugPrint(e.response!.statusCode.toString());
    }
  }

}