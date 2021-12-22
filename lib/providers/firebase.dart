
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
      displayNotification(notification); 
    });
  }

  Future<void> displayNotification(RemoteNotification message) async {
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('BroadcastID', 'Broadcast');
    IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();
    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, message.title, message.body, notificationDetails);
  }

}