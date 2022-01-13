import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
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
      Provider.of<ChatProvider>(context, listen: false).joinScreen();
      Provider.of<ChatProvider>(context, listen: false).seeMsg(
        receiverId: widget.receiverId,
        isGroup: widget.isGroup,
      );
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen();
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen();
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      Provider.of<ChatProvider>(context, listen: false).leaveScreen();
    }
  }

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      context.read<ChatProvider>().isUserTyping();
      context.read<ChatProvider>().listenToMessages();
      context.read<ChatProvider>().joinScreen();
      context.read<ChatProvider>().isUserOnline(receiverId: widget.receiverId);
      context.read<ChatProvider>().isScreenOn(userUid: widget.receiverId);
      context.read<ChatProvider>().seeMsg(receiverId: widget.receiverId, isGroup: widget.isGroup);
    });
  }

  @override 
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
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
        return WillPopScope(
          onWillPop: () {
            context.read<ChatProvider>().leaveScreen();
            context.read<ChatProvider>().clearSelectedMessages();
            return Future.value(true);
          },
          child: KeyboardDismisser(
            gestures: const [
              GestureType.onTap,
              GestureType.onPanUpdateDownDirection,
            ],
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
                                  barTitle: context.watch<ChatProvider>().isSelectedMessages ? "" :  widget.title,
                                  subTitle: context.watch<ChatProvider>().isSelectedMessages ? "" : widget.isGroup 
                                  ? context.watch<ChatProvider>().isTyping != "" 
                                  ? context.watch<ChatProvider>().isTyping 
                                  : widget.subtitle 
                                  : context.watch<ChatProvider>().isTyping != "" 
                                  ? context.watch<ChatProvider>().isTyping
                                  : context.watch<ChatProvider>().isOnline,
                                  primaryAction: context.watch<ChatProvider>().isSelectedMessages  
                                  ? PopupMenuButton(
                                      color: ColorResources.white,
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: ColorResources.white,
                                      ),
                                      itemBuilder: (context) => [
                                        if(widget.isGroup)
                                          const PopupMenuItem(
                                            child: Text("Info",
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: ColorResources.textBlackPrimary
                                              ),
                                            ),
                                            value: "info-msg",
                                          ),
                                        const PopupMenuItem(
                                          child: Text("Hapus Pesan Untuk Saya",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: ColorResources.textBlackPrimary
                                            ),
                                          ),
                                          value: "delete-msg-bulk-soft",
                                        ),
                                        const PopupMenuItem(
                                          child: Text("Hapus Untuk Semua Orang",
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: ColorResources.textBlackPrimary
                                            ),
                                          ),
                                          value: "delete-msg-bulk",
                                        ),
                                      ],
                                      onSelected: (val) {
                                        if(val == "info-msg") {
                                          showModalBottomSheet(
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10.0), 
                                                topRight: Radius.circular(10.0)
                                              ),
                                            ),
                                            context: context, 
                                            builder: (BuildContext context) {
                                              List<Readers> readers = context.watch<ChatProvider>().selectedMessages.last.readers.where((el) => el.isRead == true).toList();
                                              if(readers.isEmpty) {
                                                return SizedBox(
                                                  height: 80.0,
                                                  child: Center(
                                                    child: Text("No Views",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: Dimensions.fontSizeSmall
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                margin: EdgeInsets.all(Dimensions.marginSizeDefault),
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount: readers.length,
                                                  itemBuilder: (BuildContext context, int i) {
                                                    return Container(
                                                      margin: const EdgeInsets.only(bottom: 10.0),
                                                      child: ListTile(
                                                        contentPadding: EdgeInsets.zero,
                                                        dense: true,
                                                        leading: Container(
                                                          width: 40.0,
                                                          height: 40.0,
                                                          decoration: BoxDecoration(
                                                            image: DecorationImage(
                                                              fit: BoxFit.cover,
                                                              image: NetworkImage(readers[i].image),
                                                            ),
                                                            borderRadius: BorderRadius.circular(30.0),
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        title: Text(readers[i].name,
                                                          style: TextStyle(
                                                            fontSize: Dimensions.fontSizeDefault,
                                                            color: ColorResources.textBlackPrimary
                                                          ),
                                                        ),
                                                        subtitle: Container(
                                                          margin: const EdgeInsets.only(top: 8.0),
                                                          child: Text(DateFormat.Hm().format(readers[i].seen),
                                                            style: TextStyle(
                                                              fontSize: Dimensions.fontSizeSmall,
                                                              color: ColorResources.grey
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          );
                                        }
                                        if(val == "delete-msg-bulk-soft") {
                                          context.read<ChatProvider>().deleteMsgBulk(softDelete: true);
                                        }
                                        if(val == "delete-msg-bulk") {
                                          context.read<ChatProvider>().deleteMsgBulk(softDelete: false);
                                        }
                                      },
                                    )
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: ColorResources.white
                                    ),
                                    onPressed: () {
                                      context.read<ChatProvider>().deleteChat(context, receiverId: widget.receiverId);
                                    },
                                  ),  
                                  secondaryAction: context.watch<ChatProvider>().isSelectedMessages 
                                  ? null 
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: ColorResources.white
                                    ),
                                    onPressed: () {
                                      context.read<ChatProvider>().goBack(context);
                                      context.read<ChatProvider>().leaveScreen();
                                      context.read<ChatProvider>().clearSelectedMessages();
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
          ),
        ); 
      }
    );
  }

  Widget messageList() {
    List<ChatMessage>? messages = context.watch<ChatProvider>().messages;
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
            controller: context.read<ChatProvider>().scrollController,
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
            order: GroupedListOrder.ASC,
            shrinkWrap: true,
            reverse: true,
            indexedItemBuilder: (BuildContext context, ChatMessage items, int i) {
              ChatMessage chatMessage = messages[i];
              bool isOwnMessage = context.read<AuthenticationProvider>().userUid() == chatMessage.senderId;
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
      margin: EdgeInsets.only(left: Dimensions.marginSizeSmall, right: Dimensions.marginSizeSmall, bottom: Dimensions.marginSizeSmall),
      decoration: const BoxDecoration(
        color: ColorResources.backgroundBlueSecondary,
        borderRadius: BorderRadius.all(Radius.circular(30.0))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          messageTextField(context),
          imageMessageButton(),
          sendMessageButton(),
        ],  
      ),
    );
  }

  Widget messageTextField(BuildContext context) {
    return SizedBox(
      width: deviceWidth * 0.60,
      child: CustomTextMessageFormField(
        fillColor: Colors.transparent,
        label: Container(),
        controller: context.read<ChatProvider>().messageTextEditingController,
        focusNode: context.read<ChatProvider>().messageFocusNode,
        onSaved: (val) {},
        onChange: (val) async {
          context.read<ChatProvider>().onChangeMsg(context, val, userId: widget.currentUserId);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("msg", val);
        },
        regex: r"^(?!\s*$).+", 
        hintText: "Send a message", 
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
            title: widget.title,
            subtitle: widget.subtitle,
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
        elevation: 0.0,
        backgroundColor: const Color.fromRGBO(0, 82, 218, 1.0),
        onPressed: () {
          context.read<ChatProvider>().sendImageMessage(
            context,
            title: widget.title,
            subtitle: widget.subtitle,
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

