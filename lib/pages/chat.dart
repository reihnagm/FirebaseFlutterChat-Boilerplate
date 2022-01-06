import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chatv28/basewidget/top_bar.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isGroup;
  final String chatUid;
  final String senderId;
  final String receiverId;
  const ChatPage({ 
    required this.title,
    required this.subtitle,
    required this.isGroup,
    required this.chatUid,
    required this.senderId,
    required this.receiverId,
    Key? key 
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late double deviceHeight;
  late double deviceWidth;

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
      Provider.of<ChatProvider>(context, listen: false).joinScreen(
        chatUid: widget.chatUid,
      );
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(
        chatUid: widget.chatUid,
      );
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(
        chatUid: widget.chatUid,
      );
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(
        chatUid: widget.chatUid,
      );
    }
  }

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).listenToMessages(chatUid: widget.chatUid);
      Provider.of<ChatProvider>(context, listen: false).isUserOnline(receiverId: widget.receiverId);
      Provider.of<ChatProvider>(context, listen: false).seeMsg(
        chatUid: widget.chatUid, 
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        isGroup: widget.isGroup,
      );
      // Provider.of<ChatProvider>(context, listen: false).listenToKeyboardType(chatUid: widget.chatUid);
      Provider.of<ChatProvider>(context, listen: false).joinScreen(
        chatUid: widget.chatUid,
      );
    });
  }

  @override 
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ChatProvider>().isScreenOn(
      chatUid: widget.chatUid, 
      userUid: widget.receiverId,
    ); // Listen Message is Read
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width; 
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () {
            Provider.of<ChatProvider>(context, listen: false).isScreenOn(
              chatUid: widget.chatUid, 
              userUid: widget.receiverId,
            );
            Provider.of<ChatProvider>(context, listen: false).leaveScreen(
              chatUid: widget.chatUid,
            );
            return Future.value(true);
          },
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Column(
                    children: [
                      TopBarChat(
                        barTitle: widget.title,
                        subTitle: widget.isGroup 
                        ? widget.subtitle 
                        : context.watch<ChatProvider>().isOnline == null ? "" : context.read<ChatProvider>().isOnline,
                        primaryAction: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: ColorResources.white
                          ),
                          onPressed: () {
                             Provider.of<ChatProvider>(context, listen: false).deleteChat(context, chatUid: widget.chatUid, receiverId: widget.receiverId);
                          },
                        ),  
                        secondaryAction: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: ColorResources.white
                          ),
                          onPressed: () {
                            context.read<ChatProvider>().goBack(context, chatUid: widget.chatUid, receiverId: widget.receiverId);
                            Provider.of<ChatProvider>(context, listen: false).isScreenOn(
                              chatUid: widget.chatUid, 
                              userUid: widget.receiverId,
                            );
                            Provider.of<ChatProvider>(context, listen: false).leaveScreen(
                              chatUid: widget.chatUid,
                            );
                          },
                        ),  
                      ),
                      messageList(),
                      sendMessageForm()
                    ],
                  );
                },
              )
            ),
          ),
        ); 
      }
    );
  }

  Widget messageList() {
    if(context.watch<ChatProvider>().messages != null) {
      if(context.watch<ChatProvider>().messages!.isNotEmpty) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            child: GroupedListView<ChatMessage, dynamic>(
              physics: const ScrollPhysics(),
              controller: context.read<ChatProvider>().scrollController,
              elements: context.watch<ChatProvider>().messages!,
              groupBy: (el) => DateFormat('dd MMM yyyy').format(el.sentTime),
              groupSeparatorBuilder:(date) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0)
                      ),
                      child: Text(date,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey
                        )
                      ),
                    ),
                    const Divider(),
                  ],
                );
              },
              groupComparator: (value1, value2) => value1.compareTo(value2),
              itemComparator: (item1, item2) => DateFormat('yyyy-MM-dd').format(item1.sentTime).compareTo(DateFormat('yyyy-MM-dd').format(item2.sentTime)),
              order: GroupedListOrder.DESC,
              shrinkWrap: true,
              indexedItemBuilder: (BuildContext context, ChatMessage items, int i) {
                ChatMessage chatMessage = context.read<ChatProvider>().messages![i];
                bool isOwnMessage = chatMessage.senderId == context.read<AuthenticationProvider>().userUid();
                return CustomChatListViewTile(
                  deviceWidth: deviceWidth * 0.80, 
                  deviceHeight: deviceHeight, 
                  isGroup: widget.isGroup,
                  isOwnMessage: isOwnMessage, 
                  message: chatMessage, 
                );                
              },
            ),
          ),
        );
      } else {
        return const Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Text("Be the first to say Hi!",
              style: TextStyle(
                color: ColorResources.textBlackPrimary
              ),
            ),
          ),
        );
      }
    } else {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: ColorResources.backgroundBlueSecondary,
          ),
        ),
      );
    }
  }

  Widget sendMessageForm() {
    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.marginSizeSmall, left: Dimensions.marginSizeSmall, right: Dimensions.marginSizeSmall),
      decoration: BoxDecoration(
        color: ColorResources.backgroundBlueSecondary,
        borderRadius: BorderRadius.circular(10.0)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          messageTextField(),
          sendMessageButton(),
          imageMessageButton()
        ],  
      ),
    );
  }

  Widget messageTextField() {
    return SizedBox(
      width: deviceWidth * 0.60,
      child: CustomTextMessageFormField(
        fillColor: Colors.transparent,
        label: Container(),
        controller: context.read<ChatProvider>().messageTextEditingController,
        onSaved: (val) {},
        onChange: (val) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("msg", val);
        },
        regex: r"^(?!\s*$).+", 
        hintText: "Type a message", 
        obscureText: false,
      ),
    );
  }

  Widget sendMessageButton() {
    return IconButton(
      onPressed: () {
        if(context.read<ChatProvider>().messageTextEditingController.text.isNotEmpty) {
          context.read<ChatProvider>().sendTextMessage(
            context,
            subtitle: widget.subtitle,
            chatUid: widget.chatUid, 
            senderName: context.read<AuthenticationProvider>().chatUser!.name!,
            receiverId: widget.receiverId,
            isGroup: widget.isGroup,
          );
        }
        return;
      }, 
      icon: const Icon(
        Icons.send,
        size: 20.0,
        color: Colors.white,
      )
    );
  }

  Widget imageMessageButton() {
    return SizedBox(
      width: 30.0,
      child: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(0, 82, 218, 1.0),
        onPressed: () {
          context.read<ChatProvider>().sendImageMessage(
            context,
            subtitle: widget.subtitle,
            chatUid: widget.chatUid, 
            senderName: context.read<AuthenticationProvider>().chatUser!.name!,
            receiverId: widget.receiverId,
            isGroup: widget.isGroup,
          );
        },
        child: const Icon(
          Icons.camera_enhance,
          size: 20.0,
        ),
      ),
    );
  }

}

