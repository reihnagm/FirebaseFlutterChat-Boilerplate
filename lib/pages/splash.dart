
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/providers.dart';
import 'package:chatv28/providers/firebase.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  const SplashPage({
    required Key key,
    required this.onInitializationComplete,
  }) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override 
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((_) => {
      setup().then((_) => widget.onInitializationComplete())
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'Chatify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          backgroundColor: const Color.fromRGBO(36, 35, 49, 1.0),
          scaffoldBackgroundColor: const Color.fromRGBO(36, 35,  49, 1.0)
        ),
        home: const Scaffold(
          body: Center(
            child: Text("Chatify",
              style: TextStyle(
                fontSize: 40.0,
                color: Colors.white
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> setup() async {}
}