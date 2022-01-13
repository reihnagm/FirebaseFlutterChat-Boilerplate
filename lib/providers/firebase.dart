import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/utils/constant.dart';
const String chatCollection = "Chats";

class FirebaseProvider with ChangeNotifier {
  final AuthenticationProvider authenticationProvider; 
  final SharedPreferences sharedPreferences;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  FirebaseProvider({
    required this.sharedPreferences,
    required this.authenticationProvider
  });

  AwesomeNotifications awesomeNotifications = AwesomeNotifications();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin(); 
  AndroidInitializationSettings? androidInitializationSettings;
  IOSInitializationSettings? iosInitializationSettings;
  InitializationSettings initializationSettings = const InitializationSettings();

  // Future<void> setupInteractedMessage(BuildContext context) async {
  //   RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  //   if (initialMessage != null) {
  //     handleMessage(initialMessage, context);
  //   }
  // }

  // void handleMessage(RemoteMessage message, BuildContext context) {
    // FirebaseMessaging.onMessage.listen((event) {
    //   print("bom");  
    // });
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   Map<String, dynamic> data = message.data;
    //   String chatId = data["chatId"];
    //   String title = data["title"];
    //   String subtitle = data["subtitle"];
    //   String groupName = data["groupName"];
    //   String groupImage = data["groupImage"];
    //   String isGroup = data["isGroup"];
    //   String receiverId = data["receiverId"];
    //   String receiverName = data["receiverName"];
    //   String receiverImage = data["receiverImage"];
    //   sharedPreferences.setString("chatId", chatId);
    //   Navigator.push(context,
    //     PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    //       return ChatPage(
    //         title: title,  
    //         subtitle: subtitle,
    //         groupName: groupName,
    //         groupImage: groupImage,
    //         isGroup: isGroup == "true" ? true : false,
    //         currentUserId: authenticationProvider.userUid(),
    //         receiverId: receiverId,
    //         receiverName: receiverName,
    //         receiverImage: receiverImage,
    //         tokens: const [],
    //         members: const [],
    //       );
    //     },
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       const begin = Offset(1.0, 0.0);
    //       const end = Offset.zero;
    //       const curve = Curves.ease;
    //       var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    //       return SlideTransition(
    //         position: animation.drive(tween),
    //         child: child,
    //       );
    //     })
    //   );
    //   // db.collection(chatCollection)
    //   // .doc(chatId).update({
    //   //   "updated_at": DateTime.now()
    //   // });
    //   // Trigger update changes
    //  AwesomeNotifications().createNotification(
    //     content: NotificationContent(
    //       id: 1,
    //       color: Colors.grey,
    //       fullScreenIntent: true,
    //       displayOnBackground: true,
    //       displayOnForeground: true,
    //       notificationLayout: NotificationLayout.Default,
    //       channelKey: 'basic_channel',
    //       title: 'Title',
    //       body: 'Body'
    //     )
    //   );
    // }); 
  // }

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
      RemoteNotification notification = message.notification!;
      Map<String, dynamic> data = message.data;
      displayNotification(data, notification);
      // handleMessage(message, context);
    });
  }

  Future<void> displayNotification(Map<String, dynamic> data, RemoteNotification message) async {
    // AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('BroadcastID', 'Broadcast');
    // IOSNotificationDetails iosNotificationDetails = const IOSNotificationDetails();
    // NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);
    // await flutterLocalNotificationsPlugin.show(0, message.title, message.body, notificationDetails);
    String type = data["type"];
    if(type == "image") {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          color: Colors.grey,
          fullScreenIntent: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.BigPicture,
          bigPicture: message.body,
          channelKey: 'basic_channel',
          title: message.title,
        )
      );
    } else {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          color: Colors.grey,
          fullScreenIntent: true,
          displayOnBackground: true,
          displayOnForeground: true,
          notificationLayout: NotificationLayout.Default,
          channelKey: 'basic_channel',
          title: 'Title',
          body: 'Body'
        )
      );
    }
  }

  Future<void> sendNotification({
    required List<Token> tokens,
    required List<String> registrationIds,
    required String token, 
    required String title, 
    required String subtitle,
    required String body,
    required String chatUid,
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
        "collapse_key": "type_a",
        "notification": {
          "title": title,
          "body": "${authenticationProvider.userName()} : ${type == "image" ? "Media Attachment" : body}",
          "sound":"default"
        },
        "data": {
          "chatId": chatUid,
          "title": title,
          "subtitle": subtitle,
          "receiverId": receiverId,
          "receiverName": receiverName,
          "receiverImage": receiverImage,
          "groupName": groupName,
          "groupImage": groupImage,
          "isGroup": true,
          "type": type,
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        },
        "priority":"high"
      };
    } else {
      data = {
        "to": token,
        // "collapse_key": "type_a",
        // "notification": {
        //   "title":authenticationProvider.userName(),
        //   "body": body,
        //   "sound":"default"
        // },
        "priority":"high",
        "content_available": true,
        "data": {
          "content": {
            "id": 100,
            "channelKey": "big_picture",
            "title": "Huston!\nThe eagle has landed!",
            "body": "A small step for a man, but a giant leap to Flutter's community!",
            "notificationLayout": "BigPicture",
            "largeIcon": "https://media.fstatic.com/kdNpUx4VBicwDuRBnhBrNmVsaKU=/full-fit-in/290x478/media/artists/avatar/2013/08/neil-i-armstrong_a39978.jpeg",
            "bigPicture": "https://www.dw.com/image/49519617_303.jpg",
            "showWhen": true,
            "autoDismissible": true,
          },
          // "chatId": chatUid,
          // "title": authenticationProvider.userName(),
          // "subtitle": subtitle,
          // "receiverId": receiverId,
          // "receiverName": receiverName,
          // "receiverImage": receiverImage,
          // "groupName": "",
          // "groupImage": "",
          // "isGroup": false,
          "type": type,
        },
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