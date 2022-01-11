import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chatv28/pages/chats_group_detail.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/basewidget/top_bar.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/providers/authentication.dart';

class ChatPage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String groupName;
  final String groupImage;
  final bool isGroup;
  final String chatUid;
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final List<Token> tokens;
  final List<ChatUser> members;
  const ChatPage({ 
    required this.title,
    required this.subtitle,
    required this.groupName,
    required this.groupImage,
    required this.isGroup,
    required this.chatUid,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.tokens,
    required this.members,
    Key? key 
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late double deviceHeight;
  late double deviceWidth;
  late AuthenticationProvider authenticationProvider;
  late ChatProvider chatProvider;
  late ChatProvider chatWatchProvider;

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
      Provider.of<ChatProvider>(context, listen: false).seeMsg(
        chatUid: widget.chatUid, 
        receiverId: widget.receiverId,
        isGroup: widget.isGroup,
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
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      chatProvider.listenToMessages(chatUid: widget.chatUid);
      chatProvider.isUserOnline(receiverId: widget.receiverId);
      chatProvider.isScreenOn(chatUid: widget.chatUid, userUid: widget.receiverId);
      chatProvider.joinScreen(chatUid: widget.chatUid);
      chatProvider.seeMsg(chatUid: widget.chatUid, receiverId: widget.receiverId, isGroup: widget.isGroup);
    });
  }

  @override 
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    authenticationProvider = context.read<AuthenticationProvider>();
    chatProvider = context.read<ChatProvider>();
    chatWatchProvider = context.watch<ChatProvider>();
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width; 
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () {
           chatProvider.leaveScreen(
              chatUid: widget.chatUid,
            );
            return Future.value(true);
          },
          child: Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: [ 
                      Column(
                        children: [
                          Material(
                            color: ColorResources.transparent,
                            child: InkWell(
                              onTap: () {
                                if(widget.isGroup) {
                                  NavigationService().pushNav(context, ChatsGroupDetail(
                                    title: widget.groupName,
                                    imageUrl: widget.groupImage,
                                    currentUserId: widget.currentUserId,
                                    members: widget.members
                                  ));
                                }
                              },
                              child: TopBarChat(
                                barTitle: widget.title,
                                subTitle: widget.isGroup 
                                ? widget.subtitle 
                                : chatWatchProvider.isOnline == null ? "" : chatProvider.isOnline,
                                primaryAction: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: ColorResources.white
                                  ),
                                  onPressed: () {
                                   chatProvider.deleteChat(context, chatUid: widget.chatUid, receiverId: widget.receiverId);
                                  },
                                ),  
                                secondaryAction: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: ColorResources.white
                                  ),
                                  onPressed: () {
                                    chatProvider.goBack(context, chatUid: widget.chatUid, receiverId: widget.receiverId);
                                    chatProvider.leaveScreen(
                                      chatUid: widget.chatUid,
                                    );
                                  },
                                ),  
                              ),
                            ),
                          ),
                          messageList(),
                          sendMessageForm()
                        ],
                      ),
                    ]
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
    List<ChatMessage>? messages = chatWatchProvider.messages;
    if(messages == null) {
      return const Expanded(
        child: Center(
        child: SizedBox(
          width: 16.0,
          height: 16.0,
          child: CircularProgressIndicator(
            color: ColorResources.backgroundBlueSecondary,
          ),
        ),
      ),
    );
    }
    if(messages.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: GroupedListView<ChatMessage, dynamic>(
            physics: const ScrollPhysics(),
            controller: chatProvider.scrollController,
            elements: messages,
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
                      style: TextStyle(
                        fontSize: Dimensions.fontSizeExtraSmall,
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
            reverse: true,
            indexedItemBuilder: (BuildContext context, ChatMessage items, int i) {
              ChatMessage chatMessage = messages[i];
              bool isOwnMessage =  authenticationProvider.userUid() == chatMessage.senderId;
              return CustomChatListViewTile(
                deviceWidth: deviceWidth * 0.80, 
                deviceHeight: deviceHeight, 
                isGroup: widget.isGroup,
                isOwnMessage: isOwnMessage, 
                message: chatMessage, 
                chatUid: widget.chatUid,
              );                
            },
          ),
        ),
      );
    } else {
      return Expanded(
        child: Align(
          alignment: Alignment.center,
          child: Text("Be the first to say Hi!",
            style: TextStyle(
              fontSize: Dimensions.fontSizeSmall,
              color: ColorResources.textBlackPrimary
            ),
          ),
        ),
      );
    }
  }

  Widget sendMessageForm() {
    return Container(
      decoration: const BoxDecoration(
        color: ColorResources.backgroundBlueSecondary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
        controller: chatProvider.messageTextEditingController,
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
        if(chatProvider.messageTextEditingController!.text.isNotEmpty) {
          chatProvider.sendTextMessage(
            context,
            title: widget.title,
            subtitle: widget.subtitle,
            chatUid: widget.chatUid, 
            receiverId: widget.receiverId,
            receiverName: widget.receiverName,
            receiverImage: widget.receiverImage,
            tokens: widget.tokens,
            members: widget.members,
            groupName: widget.groupName,
            groupImage: widget.groupImage,
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
          chatProvider.sendImageMessage(
            context,
            title: widget.title,
            subtitle: widget.subtitle,
            chatUid: widget.chatUid, 
            receiverId: widget.receiverId,
            receiverName: widget.receiverName,
            receiverImage: widget.receiverImage,
            members: widget.members,
            tokens: widget.tokens,
            groupName: widget.groupName,
            groupImage: widget.groupImage,
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

