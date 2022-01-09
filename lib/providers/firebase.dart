import 'package:dio/dio.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chatv28/models/chat.dart';
import 'package:chatv28/utils/constant.dart';
import 'package:chatv28/pages/chat.dart';

class FirebaseProvider with ChangeNotifier {
      
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); 
  AndroidInitializationSettings? androidInitializationSettings;
  IOSInitializationSettings? iosInitializationSettings;
  InitializationSettings initializationSettings = const InitializationSettings();

  Future<void> setupInteractedMessage(BuildContext context) async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage, context);
    }
  }

  void handleMessage(RemoteMessage message, BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> data = message.data;
      String chatUid = data["chatUid"];
      String title = data["title"];
      String subtitle = data["subtitle"];
      String isGroup = data["isGroup"];
      String senderId = data["senderId"];
      String receiverId = data["receiverId"];
      String receiverName = data["receiverName"];
      String receiverImage = data["receiverImage"];
      Navigator.push(context,
        PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return ChatPage(
            chatUid: chatUid,
            title: title,  
            subtitle: subtitle,
            isGroup: isGroup == "true" ? true : false,
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
    }); 
  }

  Future<void> initializeNotification(BuildContext context) async {
    androidInitializationSettings = const AndroidInitializationSettings('@drawable/ic_notification');
    iosInitializationSettings = const IOSInitializationSettings();
    initializationSettings = InitializationSettings(
      android: androidInitializationSettings, 
      iOS: iosInitializationSettings
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void listenNotification(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification!;
      Map<String, dynamic> data = message.data;
      displayNotification(data, notification);
      handleMessage(message, context);
    });
  }

  Future<void> displayNotification(Map<String, dynamic> data, RemoteNotification message) async {
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('BroadcastID', 'Broadcast');
    IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, message.title, message.body, notificationDetails);
  }

  Future<void> sendNotification({
    required List<Token> tokens,
    required String token, 
    required String title, 
    required String subtitle,
    required String body,
    required String chatUid,
    required String senderId,
    required String receiverId,
    required String receiverName,
    required String receiverImage,
    required bool isGroup,
  }) async {
    Object data = {};
    if(isGroup) {
      List<String> registrationIds = [];
      for (Token item in tokens) {
        if(item.userUid != senderId) {
          registrationIds.add(item.token);
        }
      }
      data = {
        "registration_ids": registrationIds,
        "collapse_key": "type_a",
        "notification": {
          "title": title,
          "body": body,
          "sound":"default"
        },
        "data": {
          "chatUid": chatUid,
          "title": title,
          "subtitle": subtitle,
          "senderId": senderId,
          "receiverId": receiverId,
          "receiverName": receiverName,
          "receiverImage": receiverImage,
          "isGroup": true,
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "priority":"high"
      };
    } else {
      data = {
        "to": token,
        "collapse_key": "type_a",
        "notification": {
          "title": title,
          "body": body,
          "sound":"default"
        },
        "data": {
          "chatUid": chatUid,
          "title": title,
          "subtitle": subtitle,
          "senderId": senderId,
          "receiverId": receiverId,
          "receiverName": receiverName,
          "receiverImage": receiverImage,
          "isGroup": false,
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "priority":"high"
      };
    }
    try {
      Dio dio = Dio();
      Response res = await dio.post("https://fcm.googleapis.com/fcm/send", 
        data: data,
        options: Options(
          headers: {
            "Authorization": "key=${AppConstants.firebaseKey}"
          }
        )
      );
      debugPrint(res.statusCode.toString());
    } on DioError catch(e) {
      debugPrint(e.response!.data.toString());
      debugPrint(e.response!.statusMessage.toString());
      debugPrint(e.response!.statusCode.toString());
    }
  }

}