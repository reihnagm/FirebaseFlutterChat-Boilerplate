import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chatv28/utils/global.dart';

import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/providers/firebase.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/providers.dart';
import 'package:chatv28/pages/splash.dart';
import 'package:chatv28/pages/home.dart';
import 'package:chatv28/pages/login.dart';

import 'container.dart' as core;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AwesomeNotifications().initialize('resource://drawable/ic_notification',
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.grey,
        ledColor: Colors.white,
        playSound: true,
        enableLights: true,
        enableVibration: true
      )
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupkey: 'basic_channel_group',
        channelGroupName: 'Basic group'
      )
    ],
    debug: false
  );
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // FirebaseMessaging.onMessageOpenedApp.listen((event) {
  //   AwesomeNotifications().actionStream.listen(
  //     (ReceivedNotification receivedNotification) {
  //       navigatorKey.currentState!.push(PageRouteBuilder(pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
  //         return const HomePage(currentPage: 1);
  //       },
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         const begin = Offset(1.0, 0.0);
  //         const end = Offset.zero;
  //         const curve = Curves.ease;
  //         var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  //         return SlideTransition(
  //           position: animation.drive(tween),
  //           child: child,
  //         );
  //       }));
  //     });
  // });
  await core.init();
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
    ),
  );
}

// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async { 
//   String title = message.data["title"];
//   String subtitle = message.data["subtitle"];
//   AwesomeNotifications().createNotification(
//     content: NotificationContent(
//       id: 1,
//       color: Colors.transparent,
//       fullScreenIntent: true,
//       displayOnBackground: true,
//       displayOnForeground: true,
//       icon: 'resource://drawable/ic_notification',
//       channelKey: 'basic_channel',
//       title: title,
//       body: subtitle
//     )
//   );
// }

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
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override 
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360.0, 640.0),
      builder: () {
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
            builder: (context) {
              context.read<FirebaseProvider>().setupInteractedMessage();
              context.read<FirebaseProvider>().listenNotification(context);
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
  }
}


