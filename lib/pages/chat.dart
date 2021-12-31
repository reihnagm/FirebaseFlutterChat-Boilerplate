import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/basewidget/top_bar.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/models/chat.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  const ChatPage({ 
    required this.chat,
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
        chatUid: widget.chat.uid,
        token: widget.chat.recepients.first.token!
      );
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(chatUid: widget.chat.uid);
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(chatUid: widget.chat.uid);
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen(chatUid: widget.chat.uid);
    }
  }

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      Provider.of<ChatProvider>(context, listen: false).joinScreen(
        chatUid: widget.chat.uid,
        token: widget.chat.recepients.first.token!
      );
      Provider.of<ChatProvider>(context, listen: false).listenToMessages(chatUid: widget.chat.uid);
    });
  }

  @override 
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ChatProvider>(context).isScreenOn(
      chatUid: widget.chat.uid, 
      userUid: widget.chat.recepients.first.uid!
    );
    // Provider.of<ChatProvider>(context).listenToKeyboardType(chatUid: widget.chat.uid);
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width; 
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.03,
                    vertical: deviceHeight * 0.02
                  ),
                  width: double.infinity,
                  height: deviceHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TopBar(
                        widget.chat.title(),
                        fontSize: Dimensions.fontSizeDefault,
                        barTitleColor: ColorResources.textBlackPrimary,
                        primaryAction: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: ColorResources.backgroundBlackPrimary
                          ),
                          onPressed: () {
                            context.read<ChatProvider>().deleteChat(context, chatUid: widget.chat.uid);
                          },
                        ),  
                        secondaryAction: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: ColorResources.backgroundBlackPrimary
                          ),
                          onPressed: () {
                            context.read<ChatProvider>().goBack(context);
                            Provider.of<ChatProvider>(context, listen: false).leaveScreen(chatUid: widget.chat.uid);
                          },
                        ),  
                      ),
                      messageList(),
                      sendMessageForm()
                    ],
                  ),
                );
              },
            )
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
              groupSeparatorBuilder: (date) {
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
                bool isOwnMessage = chatMessage.senderID == context.read<AuthenticationProvider>().auth.currentUser!.uid;
                return CustomChatListViewTile(
                  deviceWidth: deviceWidth * 0.80, 
                  deviceHeight: deviceHeight, 
                  isOwnMessage: isOwnMessage, 
                  message: chatMessage, 
                );                
              },
            ),
          ),
        );
      } else {
        return const Align(
          alignment: Alignment.center,
          child: Text("Be the first to say Hi!",
            style: TextStyle(
              color: ColorResources.textBlackPrimary
            ),
          ),
        );
      }
    } else {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorResources.backgroundBluePrimary,
        ),
      );
    }
  }

  Widget sendMessageForm() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: boxShadow,
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
            chatUid: widget.chat.uid, 
            receiverId: widget.chat.recepients.first.uid!,
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
          context.read<ChatProvider>().sendImageMessage(chatUid: widget.chat.uid, receiverId: widget.chat.recepients.first.uid!);
        },
        child: const Icon(
          Icons.camera_enhance,
          size: 20.0,
        ),
      ),
    );
  }

}

