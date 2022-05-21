import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/utils/custom_themes.dart';
import 'package:chat/utils/dimensions.dart';
import 'package:chat/utils/color_resources.dart';

import 'package:chat/providers/authentication.dart';
import 'package:chat/providers/chats.dart';

import 'package:chat/basewidgets/custom_list_view_tiles.dart';
import 'package:chat/basewidgets/top_bar.dart';

import 'package:chat/basewidgets/animated_dialog/show_animate_dialog.dart';
import 'package:chat/basewidgets/dialog/signout.dart';

import 'package:chat/models/chat_message.dart';
import 'package:chat/models/chat.dart';

import 'package:chat/services/navigation.dart';

import 'package:chat/views/screens/chat/chat.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({ Key? key }) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late double deviceHeight;
  late double deviceWidth;

  late AuthenticationProvider ap;
  late ChatsProvider cp;

  @override 
  void initState() {
    super.initState();
 
    Future.delayed(Duration.zero, () {
      if(mounted) {
        cp.getChats();
      }
      // if(mounted) {
      //   cp.getTokensByChat();
      // }
    });
  }

  @override 
  void dispose() {
    super.dispose();
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
           
        ap = context.read<AuthenticationProvider>();
        cp = context.read<ChatsProvider>();

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
    List<Chat>? chats = context.watch<ChatsProvider>().chats;
    return Expanded(
      child: (() {
        if(chats == null) {
          return const Center(
            child: SizedBox(
              width: 8.0,
              height: 8.0,
              child: CircularProgressIndicator(
                color: ColorResources.loaderBluePrimary,
              ),
            ),
          );
        }
        if(chats.isNotEmpty) {
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (BuildContext context, int i) {
              return chatTile(context, chats[i]);
            } 
          );
        } else {
          return Center(
            child: Text("No Chats Found.",
              style: dongleLight.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: ColorResources.textBlackPrimary
              ),
            ),
          );
        } 
      })()
    );
  }

  Widget chatTile(BuildContext context, Chat chat) {
    String subtitle = "";
    String content = "";
    if(chat.messages.isNotEmpty) {
      subtitle = chat.messages.first.type == MessageType.image 
      ? "Media Attachment" 
      : chat.messages.first.content;
    }
    content = chat.group 
    ? chat.messages.isNotEmpty 
    ? chat.messages.first.senderName 
    : subtitle 
    : subtitle;

    bool isOwnMessage = chat.messages.isNotEmpty 
    ? context.read<AuthenticationProvider>().userId() == chat.messages.last.senderId 
    : context.read<AuthenticationProvider>().userId() == chat.currentUserId;
    return CustomListViewTileWithoutActivity(
      height: deviceHeight * 0.10, 
      group: chat.group,
      title: chat.title(), 
      subtitle: content,
      contentGroup: subtitle,
      messageType: chat.type(),
      receiverName: chat.group ? chat.receiverTyping() : chat.recepients.first.name!,
      imagePath: chat.image(), 
      isActivity: chat.isTyping(), 
      readCount: chat.readCount(),
      isRead: chat.isRead(),
      isOwnMessage: isOwnMessage,
      onLongPress: () {
        if(!chat.group) {
          showDialog(
            context: context, 
            barrierDismissible: true,
            builder: (cn) {
              return AlertDialog(
                backgroundColor: ColorResources.transparent,
                elevation: 0,
                content: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        left: 35.0,
                        top: 35.0,
                        right: 35.0,
                        bottom: 35.0
                      ),
                      margin: const EdgeInsets.only(top: 45.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color:ColorResources.white,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Hapus semua pesan dengan ${chat.recepients.first.name} ?",
                            style: dongleLight.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              fontWeight: FontWeight.bold,
                              color: ColorResources.black
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 20.0,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(cn, rootNavigator: true).pop();
                                    },
                                    child: Container(
                                      height: 30.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        color: ColorResources.loaderBluePrimary,
                                      ),
                                      child: Center(
                                        child: Text("Batal",
                                          style: dongleLight.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ColorResources.white
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async { 
                                      Navigator.of(context).pop();
                                      await context.read<ChatsProvider>().deleteChat(chatId: chat.uid);
                                    },  
                                    child: Container(
                                      height: 30.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        color: ColorResources.error,
                                      ),
                                      child: Center(
                                        child: Text("Ok",
                                          style: dongleLight.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ColorResources.white
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("chatId", chat.uid);
        NavigationService().pushNav(context, ChatPage(
          avatar: chat.group ? chat.groupData.image : chat.recepients.first.image!,
          title: chat.title(),
          subtitle: chat.subtitle(),
          groupName: chat.groupData.name,
          groupImage: chat.groupData.image,
          isGroup: chat.group,
          receiverId: chat.recepients.first.uid!, 
          receiverName: chat.recepients.first.name!,
          receiverImage: chat.group ? "" : chat.recepients.first.image!,
        ));
      }
    );
  }
}