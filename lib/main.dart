import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  await Firebase.initializeApp();
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
      await databaseService.setOnChatsUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, true);
      await databaseService.updateUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, true);
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      await databaseService.updateUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
      await databaseService.setOnChatsUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      await databaseService.updateUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
      await databaseService.setOnChatsUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      await databaseService.setOnChatsUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
      await databaseService.updateUserOnline(Provider.of<AuthenticationProvider>(context, listen: false).auth.currentUser!.uid, false);
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
    return MaterialApp(
      title: "Chatify",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: const Color.fromRGBO(36, 35, 49, 1.0),
        scaffoldBackgroundColor: const Color.fromRGBO(36, 35, 49, 1.0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(30, 29, 37, 1.0),
        )
      ),
      home: Builder(
        builder: (context) {
          Provider.of<AuthenticationProvider>(context, listen: false).initAuthStateChanges();
          Provider.of<FirebaseProvider>(context, listen: false).initializeNotification(context);
          Provider.of<FirebaseProvider>(context, listen: false).listenNotification(context);
          return Consumer<AuthenticationProvider>(
            builder: (BuildContext context, AuthenticationProvider authenticationProvider, Widget? child) {
              if(authenticationProvider.chatUser == null) {
                return const LoginPage();
              }
              if(authenticationProvider.chatUser != null) {
                return const HomePage();
              }
              return MultiProvider(
                providers: providers,
                child: const MainApp()
              );
            },
          );
          // return FutureBuilder(
          //   future: Provider.of<AuthenticationProvider>(context, listen: false).initAuthStateChanges(),
          //   builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
          //     if(snapshot.connectionState == ConnectionState.waiting) {
          //       return Container();
          //     }
          //     if(Provider.of<AuthenticationProvider>(context, listen: false).chatUser != null) {
          //       return const HomePage();
          //     }
          //     return const LoginPage();
          //   },
          // );
        },
      )
    );
  }
}


