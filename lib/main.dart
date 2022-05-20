import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:chat/utils/utils.dart';
import 'package:chat/utils/global.dart';
import 'package:chat/utils/color_resources.dart';

import 'package:chat/views/screens/chat/chat.dart';

import 'package:chat/services/database.dart';
import 'package:chat/services/notification.dart';

import 'package:chat/providers/authentication.dart';
import 'package:chat/providers/firebase.dart';
import 'package:chat/providers.dart';

import 'package:chat/views/screens/splash.dart';
import 'package:chat/views/screens/home.dart';
import 'package:chat/views/screens/auth/login.dart';

import 'container.dart' as core;

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Map<String, dynamic> data = message.data;
  // Map<String, dynamic> payload = json.decode(data["payload"]);
  // if(payload["type"] == "image") {
  //   AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: Utils.createUniqueId(),
  //       channelKey: 'chat',
  //       largeIcon: payload["avatar"],
  //       bigPicture: payload["body"],
  //       title: payload["title"],
  //       body: "",
  //       notificationLayout: NotificationLayout.BigPicture,
  //       fullScreenIntent: true,
  //       displayOnBackground: true,
  //       displayOnForeground: true,
  //       roundedBigPicture: true,
  //       roundedLargeIcon: true,
  //       wakeUpScreen: true,
  //       showWhen: true
  //     )
  //   );
  // } else {
    // AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: Utils.createUniqueId(),
    //     channelKey: 'chat',
    //     largeIcon: payload["avatar"],
    //     title: payload["title"],
    //     body: payload["body"],
    //     fullScreenIntent: true,
    //     displayOnBackground: true,
    //     displayOnForeground: true,
    //     roundedLargeIcon: true,
    //     wakeUpScreen: true,
    //   )
    // );
    
  // }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Helper.initSharedPreferences();
  await Firebase.initializeApp();
  await core.init();
  // AwesomeNotifications().initialize(
  //   'resource://drawable/ic_notification',
  //   [
  //     NotificationChannel(
  //       channelKey: 'chat',
  //       channelName: 'chat_channel',
  //       channelDescription: 'chat_channel',
  //       importance: NotificationImportance.High,
  //       channelShowBadge: true,
  //     ),
  //   ],
  // );
  runApp(
    SplashPage(
      key: UniqueKey(), 
      onInitializationComplete: () {
        runApp(
          MultiProvider(
            providers: providers,
            child: const MainApp()
          )
        );
      }
    )
  );
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {

  DatabaseService databaseService = DatabaseService();

  @override 
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state); 
    /* Lifecycle */
    // - Resumed (App in Foreground)
    // - Inactive (App Partially Visible - App not focused)
    // - Paused (App in Background)
    // - Detached (View Destroyed - App Closed)
    if(state == AppLifecycleState.resumed) {
      debugPrint("=== APP RESUME ===");
      await databaseService.updateUserOnlineToken(context.read<AuthenticationProvider>().userId(), true);
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      await databaseService.updateUserOnlineToken(context.read<AuthenticationProvider>().userId(), false);
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      await databaseService.updateUserOnlineToken(context.read<AuthenticationProvider>().userId(), false);
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      await databaseService.updateUserOnlineToken(context.read<AuthenticationProvider>().userId(), false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    //   if(!isAllowed) {
    //     showDialog(
    //       context: context, 
    //       builder: (BuildContext context) {
    //         return AlertDialog(
    //           title: const Text('Allow Notifications'),
    //           content: const Text('Our app would like to send you notifications'),
    //           actions: [
    //             TextButton(
    //               onPressed: () {
    //                 Navigator.of(context).pop();
    //               },
    //               child: const Text('Don\'t allow',
    //                 style: TextStyle(
    //                   fontSize: 18.0,
    //                   color: Colors.grey
    //                 ),
    //               )
    //             ),
    //             TextButton(
    //               onPressed: () => AwesomeNotifications().requestPermissionToSendNotifications().then((_ ) => Navigator.of(context).pop()),
    //               child: const Text('Allow',
    //                 style: TextStyle(
    //                   fontSize: 18.0,
    //                   color: Colors.teal,
    //                   fontWeight: FontWeight.bold
    //                 ),
    //               )
    //             ),
    //           ],
    //         );    
    //       },
    //     );
    //   }
    // }); 
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    context.read<FirebaseProvider>().setupInteractedMessage();
    context.read<FirebaseProvider>().listenNotification(context);
    NotificationService.init();
    listenOnClickNotifications();
    
    // AwesomeNotifications().displayedStream.listen((notification) async {
    //   Utils.prefs!.setString("channel", notification.channelKey!);
    // });
      
    //   AwesomeNotifications().actionStream.listen((notification) async {
    //     Map<String, dynamic> notifications = json.decode(Utils.prefs!.getString("notifications")!);
    //     Utils.prefs!.setString("chatId", notifications["chatId"]);
    //     if(Utils.prefs!.getString("channel") == "chat") {
    //       GlobalVariable.navState.currentState!.push(
    //         PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    //           return ChatPage(
    //             avatar: notifications["avatar"],
    //             title: notifications["title"],  
    //             subtitle: notifications["subtitle"],
    //             groupName: notifications["groupName"],
    //             groupImage: notifications["groupImage"],
    //             isGroup: notifications["isGroup"] == "true" ? true : false,
    //             receiverId: notifications["receiverId"],
    //             receiverName: notifications["receiverName"],
    //             receiverImage: notifications["receiverImage"],
    //             tokens: const [],
    //             members: const [],
    //           );
    //         },
    //         transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //           const begin = Offset(1.0, 0.0);
    //           const end = Offset.zero;
    //           const curve = Curves.ease;
    //           var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    //           return SlideTransition(
    //             position: animation.drive(tween),
    //             child: child,
    //           );
    //         })
    //       );
    //       Utils.prefs!.remove("channel");
    //     }
    //   });
  }

  @override
  void dispose() {
    // AwesomeNotifications().actionSink.close();
    // AwesomeNotifications().createdSink.close();
    // AwesomeNotifications().displayedSink.close();
    // AwesomeNotifications().dispose();
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
  }

  void listenOnClickNotifications() => NotificationService.onNotifications.stream.listen(onClickedNotification);

  void onClickedNotification(String? payload) async {
    Map<String, dynamic> notifications = json.decode(Helper.prefs!.getString("notifications")!);
    if(payload == "chat.detail") {
      Helper.prefs!.setString("chatId", notifications["chatId"]);
      GlobalVariable.navState.currentState!.pushAndRemoveUntil(
        PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
          return ChatPage(
            avatar: notifications["avatar"],
            title: notifications["title"],  
            subtitle: notifications["subtitle"],
            groupName: notifications["groupName"],
            groupImage: notifications["groupImage"],
            isGroup: notifications["isGroup"] == "true" ? true : false,
            receiverId: notifications["receiverId"],
            receiverName: notifications["receiverName"],
            receiverImage: notifications["receiverImage"],
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
  }

  @override 
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return ScreenUtilInit(
          designSize: const Size(360.0, 640.0),
          builder: (BuildContext context, Widget? child) {
            return MaterialApp(
              title: "Chatify",
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                backgroundColor: ColorResources.backgroundColor,
                scaffoldBackgroundColor: ColorResources.backgroundColor,
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: ColorResources.backgroundBlueSecondary,
                )
              ),
              navigatorKey: GlobalVariable.navState,
              home: Builder(
                builder: (BuildContext context) {
                  return Consumer<AuthenticationProvider>(
                    builder: (BuildContext context, AuthenticationProvider authenticationProvider, Widget? child) {
                      if(authenticationProvider.isLogin()) {
                        return const HomePage(currentPage: 0);
                      } else {
                        return const LoginPage();
                      }
                    },
                  );
                },
              )
            );
          },
        );
      },
    );
  }
}


