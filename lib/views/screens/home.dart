import 'package:flutter/material.dart';

import 'package:chat/utils/custom_themes.dart';
import 'package:chat/utils/dimensions.dart';
import 'package:chat/utils/color_resources.dart';

import 'package:chat/views/screens/users.dart';
import 'package:chat/views/screens/chat/chats.dart';

class HomePage extends StatefulWidget {
  final int currentPage;
  const HomePage({ 
    this.currentPage = 0,
    Key? key }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;

  List<Widget> pages = [
    const ChatsPage(),
    const UsersPage()
  ];

  @override
  Widget build(BuildContext context) {
    return buildUI(context);
  }

  Widget buildUI(context) {
    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: (index) {
          setState(() {
            currentPage = index;
          });
        },
        selectedLabelStyle: dongleLight.copyWith(
          fontSize: Dimensions.fontSizeDefault,
        ),
        unselectedLabelStyle: dongleLight.copyWith(
          fontSize: Dimensions.fontSizeDefault,
        ),
        selectedItemColor: ColorResources.white,
        unselectedItemColor: ColorResources.gainsBoro,
        items: const [
          BottomNavigationBarItem(
            label: "Chats",
            icon: Icon(Icons.chat_bubble_sharp)
          ),
          BottomNavigationBarItem(
            label: "Users",
            icon: Icon(Icons.supervised_user_circle)
          )
        ],
      ),
    );
  }
}