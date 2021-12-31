
import 'package:chatv28/utils/color_resources.dart';
import 'package:flutter/material.dart';

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
          children: const [
            Text("Chatify",
              style: TextStyle(
                color: ColorResources.white,
                fontSize: 40.0,
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(width: 3.0),
            Icon(
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