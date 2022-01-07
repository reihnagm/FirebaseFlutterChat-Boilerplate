import 'package:dio/dio.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/utils/constant.dart';
import 'package:chatv28/pages/chat.dart';

class FirebaseProvider with ChangeNotifier {
      
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); 
  AndroidInitializationSettings? androidInitializationSettings;
  IOSInitializationSettings? iosInitializationSettings;
  InitializationSettings initializationSettings = const InitializationSettings();

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
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Map<String, dynamic> data = message.data;
      String chatUid = data["chatUid"];
      String title = data["title"];
      String subtitle = data["subtitle"];
      String isGroup = data["isGroup"];
      String senderId = data["senderId"];
      String receiverId = data["receiverId"];
      NavigationService().pushNav(context, 
        ChatPage(
          chatUid: chatUid,
          title: title,  
          subtitle: subtitle,
          isGroup: isGroup == "true" ? true : false,
          senderId: senderId,
          receiverId: receiverId,
        )
      );
    });
  }

  Future<void> displayNotification(Map<String, dynamic> data, RemoteNotification message) async {
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('BroadcastID', 'Broadcast');
    IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, message.title, message.body, notificationDetails);
  }

  Future<void> sendNotification({
    required String token, 
    required String title, 
    required String subtitle,
    required String body,
    required String chatUid,
    required String senderId,
    required String receiverId,
    required bool isGroup,
  }) async {
    try {
      Dio dio = Dio();
      Response res = await dio.post("https://fcm.googleapis.com/fcm/send", 
        data: {
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
            "isGroup": isGroup,
            "click_action": "FLUTTER_NOTIFICATION_CLICK"
          },
          "priority":"high"
        },
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