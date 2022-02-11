import 'dart:async';
import 'dart:convert';

// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:chatv28/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/utils/global.dart';
import 'package:chatv28/services/notification.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/utils/constant.dart';

class FirebaseProvider with ChangeNotifier {
  final AuthenticationProvider authenticationProvider; 
  final SharedPreferences sharedPreferences;

  FirebaseProvider({
    required this.sharedPreferences,
    required this.authenticationProvider
  });

  Future<void> setupInteractedMessage() async {
    await FirebaseMessaging.instance.getInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> data = message.data;
      Map<String, dynamic> payload = json.decode(data["payload"]);
      if(payload["screen"] == "chat.detail") {
        sharedPreferences.setString("chatId", payload["chatId"]);
        GlobalVariable.navState.currentState!.pushAndRemoveUntil(
          PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
            return ChatPage(
              avatar: payload["avatar"],
              title: payload["title"],  
              subtitle: payload["subtitle"],
              groupName: payload["groupName"],
              groupImage: payload["groupImage"],
              isGroup: payload["isGroup"] == "true" ? true : false,
              receiverId: payload["receiverId"],
              receiverName: payload["receiverName"],
              receiverImage: payload["receiverImage"],
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
          }), (Route<dynamic> route) => route.isFirst
        );
      } 
    });
  }


  void listenNotification(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // RemoteNotification notification = message.notification!;
      Map<String, dynamic> data = message.data;
      Map<String, dynamic> payload = json.decode(data["payload"]);
      sharedPreferences.setString("notifications", json.encode({
        "chatId": payload["chatId"],
        "avatar": payload["avatar"],
        "title": payload["title"],
        "subtitle": payload["subtitle"],
        "body": payload["body"],
        "receiverId": payload["receiverId"],
        "receiverName": payload["receiverName"],
        "receiverImage": payload["receiverImage"],
        "groupName": payload["groupName"],
        "groupImage": payload["groupImage"],
        "isGroup": payload["isGroup"],
        "type": payload["type"],
        "tokens": payload["tokens"],
        "members": payload["members"]
      }));
      NotificationService.showNotification(
        title: payload["title"],
        body: payload["body"],
        payload: payload,
      );
    });
  }

  Future<void> sendNotification({
    required List registrationIds,
    required List tokens,
    required List members,
    required String token, 
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
        "collapse_key": "New Message",
        "priority":"high",
        "notification": {
          "title": title,
          "body": type == "image" 
          ? "${authenticationProvider.userName()} Media Attachment" 
          : "${authenticationProvider.userName()} $body",
          "sound":"default"
        },
        "android": {
          "notification": {
            "channel_id": "chat"
          }
        },
        "data": {
          "payload": {
            "chatId": chatId,
            "avatar": groupImage, 
            "title": title,
            "subtitle": subtitle,
            "body": type == "image" 
            ? "${authenticationProvider.userName()} Media Attachement"  
            : "${authenticationProvider.userName()} $body",
            "bodyImg": body,
            "receiverId": receiverId,
            "receiverName": receiverName,
            "receiverImage": receiverImage,
            "groupName": groupName,
            "groupImage": groupImage,
            "isGroup": "true",
            "type": type,
            "tokens": tokens,
            "members": members,
            "screen": "chat.detail"
          },
        },
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
      };
    } else {
      data = {
        "to": token,
        "collapse_key" : "New Message",
        "priority":"high",
        "notification": {
          "title": authenticationProvider.userName(),
          "body": type == "image" 
          ? "Media Attachment" 
          : body,
          "sound":"default",
        },
        "android": {
          "notification": {
            "channel_id": "chat",
          }
        },
        "data": {
          "payload": {
            "chatId": chatId,
            "avatar": authenticationProvider.userImage(),
            "title": authenticationProvider.userName(),
            "subtitle": subtitle,
            "body": type == "image" 
            ? "Media Attachment" 
            : body,
            "bodyImg": body,
            "receiverId": receiverId,
            "receiverName": receiverName,
            "receiverImage": receiverImage,
            "groupName": "-",
            "groupImage": "-",
            "isGroup": "false",
            "type": type,
            "tokens": "-",
            "members": "-",
            "screen": "chat.detail",
          },
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        },
      };
    }
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