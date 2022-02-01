import 'package:flutter/material.dart';

import 'package:chatv28/utils/custom_themes.dart';
import 'package:chatv28/utils/color_resources.dart';

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
    Future.delayed(const Duration(seconds: 1)).then((_) => {
      setup().then((_) => widget.onInitializationComplete())
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: ColorResources.backgroundBluePrimary,
        scaffoldBackgroundColor: ColorResources.backgroundBlueSecondary
      ),
      home: Scaffold(
        body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Chatify",
              style: dongleLight.copyWith(
                color: ColorResources.white,
                fontWeight: FontWeight.bold,
                fontSize: 60,
              ),
            ),
            const SizedBox(width: 3.0),
            const Icon(
              Icons.chat_bubble_rounded,
              size: 20.0,  
              color: Colors.white,
            ),
          ],
        ) 
      ),
    ),
  );
}

  Future<void> setup() async {}
}