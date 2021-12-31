import 'package:dio/dio.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      debugPrint(data.toString());
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
    required String body,
    required String chatUid
  }) async {
    try {
      Dio dio = Dio();
      Response res = await dio.post("https://fcm.googleapis.com/fcm/send", 
        data: {
          "to": token,
          "collapse_key": "chat",
          "notification": {
            "title": title,
            "body": body,
            "sound":"default"
          },
          "data": {
            "chatUid": chatUid,
          },
          "priority":"high"
        },
        options: Options(
          headers: {
            "Authorization": "key=AAAALAULPvE:APA91bH3xGzHcM3tWs5CKOyzdcfmjt8_z_htqRTSqlE47Cx6BmY8oTTQJ5QJngIlYzz5w-sbSyB1iigaQIonS3yDZVSVlvwDzH7rk4tIegawxlwjlt3_9rOnolDlsGh_Dnk1THSRKmnq"
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