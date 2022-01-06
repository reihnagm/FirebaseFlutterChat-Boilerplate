import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/basewidget/animated_dialog/show_animate_dialog.dart';
import 'package:chatv28/basewidget/signout_confirmation_dialog/signout_confirmation_dialog.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/providers/chats.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/basewidget/top_bar.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({ Key? key }) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late double deviceHeight;
  late double deviceWidth;

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Provider.of<AuthenticationProvider>(context, listen: false).initAuthStateChanges();
      Provider.of<ChatsProvider>(context, listen: false).getChats();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorResources.backgroundColor
          ),
          padding: EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.03,
            vertical: deviceHeight * 0.02
          ),
          height: deviceHeight * 0.98,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TopBar(
                barTitle: "Chats",
                barTitleColor: ColorResources.textBlackPrimary,
                primaryAction: IconButton(
                  onPressed: () {
                    showAnimatedDialog(context,
                      const SignOutConfirmationDialog(),
                      isFlip: false
                    );
                  }, 
                  icon: const Icon(
                    Icons.logout,
                    color: ColorResources.textBlackPrimary
                  )
                ),
              ),
              chatList()
            ],
          ),
        );
      },
    );
  }

  Widget chatList() {
    return Expanded(
      child: (() {
        if(context.watch<ChatsProvider>().chats != null) {
          if(context.watch<ChatsProvider>().chats!.isNotEmpty) {
            return ListView.builder(
              itemCount:context.watch<ChatsProvider>().chats!.length,
              itemBuilder: (BuildContext context, int i) {
                return chatTile(context, context.watch<ChatsProvider>().chats![i]);
              } 
            );
          } else {
            return const Center(
              child: Text("No Chats Found.",
                style: TextStyle(
                  color: ColorResources.textBlackPrimary
                ),
              ),
            );
          }
        } else {
          return const Center(
            child: SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                color: ColorResources.backgroundBlueSecondary,
              ),
            ),
          );
        }
      })(),
    ); 
  }

  Widget chatTile(BuildContext context, Chat chat) {
    String subtitleText = "";
    if(chat.messages.isNotEmpty) {
      subtitleText = chat.messages.first.type == MessageType.image 
      ? "Media Attachment" 
      : chat.messages.first.content;
    }
    
    return CustomListViewTileWithoutActivity(
      height: deviceHeight * 0.10, 
      group: chat.group,
      title: chat.title(), 
      subtitle: subtitleText, 
      imagePath: chat.image(), 
      isActivity: chat.activity, 
      readCount: chat.readCount(),
      isRead: chat.isRead(),
      onTap: () {
        NavigationService.pushNav(context, ChatPage(
          title: chat.title(),
          subtitle: chat.subtitle(),
          isGroup: chat.group,
          chatUid: chat.uid,
          senderId: context.read<AuthenticationProvider>().userUid(),
          receiverId: chat.recepients.first.uid!, 
        ));
      }
    );
  }

 

}