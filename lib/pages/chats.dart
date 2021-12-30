import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatv28/basewidget/animated_dialog/show_animate_dialog.dart';
import 'package:chatv28/basewidget/signout_confirmation_dialog/signout_confirmation_dialog.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/providers/authentication.dart';
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
  late DatabaseService databaseService;

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      Provider.of<AuthenticationProvider>(context, listen: false).initAuthStateChanges();
      Provider.of<ChatsProvider>(context, listen: false).getChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    databaseService = DatabaseService();
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
              TopBar("Chats",
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
    List<Chat>? chats = context.watch<ChatsProvider>().chats;
    return Expanded(
      child: (() {
        if(chats != null) {
          if(chats.isNotEmpty) {
            return ListView.builder(
              itemCount: chats.length ,
              itemBuilder: (BuildContext context, int i) {
                return chatTile(context, chats[i]);
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
            child: CircularProgressIndicator(
              color: ColorResources.backgroundBlueSecondary,
            ),
          );
        }
      })() ,
    );
  }

  Widget chatTile(BuildContext context, Chat chat) {
    String subtitleText = "";
    if(chat.messages.isNotEmpty) {
      subtitleText = chat.messages.first.type == MessageType.image 
      ? "Media Attachment" 
      : chat.messages.first.content;
    }
    return CustomListViewTileWithActivity(
      height: deviceHeight * 0.10, 
      title: chat.title(), 
      subtitle: subtitleText, 
      imagePath: chat.imageURL(), 
      isActive: chat.isUsersOnline(), 
      isActivity: chat.activity, 
      readCount: chat.readCount(),
      isRead: chat.isRead(),
      onTap: () async {
        await databaseService.seeMsg(
          chatUid: chat.uid, 
          senderId: chat.recepients.first.uid!,
          userUid: chat.currentUserId
        );
        NavigationService.pushNav(context, ChatPage(chat: chat));
      }
    );
  }

 

}