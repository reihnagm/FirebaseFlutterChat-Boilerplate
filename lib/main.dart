import 'package:chatv28/providers/firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        runApp(const MainApp());
      }
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override 
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
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
            Provider.of<FirebaseProvider>(context, listen: false).initializeNotification(context);
            Provider.of<FirebaseProvider>(context, listen: false).listenNotification(context);
            return StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
                User? user = snapshot.data as User?;
                if(user != null) {
                  return const HomePage();
                }
                return const LoginPage();
              },
            );
          },
        )
      ),
    );
  }
}


