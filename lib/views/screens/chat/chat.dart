import 'dart:async';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat/models/chat_message.dart';

import 'package:chat/views/screens/chat/chats_group_detail.dart';

import 'package:chat/services/navigation.dart';

import 'package:chat/basewidgets/custom_input_fields.dart';
import 'package:chat/basewidgets/custom_list_view_tiles.dart';
import 'package:chat/basewidgets/top_bar.dart';

import 'package:chat/utils/custom_themes.dart';
import 'package:chat/utils/color_resources.dart';
import 'package:chat/utils/dimensions.dart';

import 'package:chat/providers/chat.dart';
import 'package:chat/providers/authentication.dart';

class ChatPage extends StatefulWidget {
  final String avatar;
  final String title;
  final String subtitle;
  final String groupName;
  final String groupImage;
  final bool isGroup;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  const ChatPage({ 
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.groupName,
    required this.groupImage,
    required this.isGroup,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    Key? key 
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late double deviceHeight;
  late double deviceWidth;
  late ChatProvider cp;
  
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
      context.read<ChatProvider>().joinScreen();
      context.read<ChatProvider>().seeMsg(
        receiverId: widget.receiverId,
        isGroup: widget.isGroup,
      );
      context.read<ChatProvider>().leaveScreen();
      context.read<ChatProvider>().isUserOnline(receiverId: widget.receiverId);
    }
    if(state == AppLifecycleState.inactive) {
      debugPrint("=== APP INACTIVE ===");
      context.read<ChatProvider>().leaveScreen();
      context.read<ChatProvider>().isUserOnline(receiverId: widget.receiverId);
      context.read<ChatProvider>().toggleIsActivity(isActive: false);
    }
    if(state == AppLifecycleState.paused) {
      debugPrint("=== APP PAUSED ===");
      context.read<ChatProvider>().isUserOnline(receiverId: widget.receiverId);
      context.read<ChatProvider>().leaveScreen();
    }
    if(state == AppLifecycleState.detached) {
      debugPrint("=== APP CLOSED ===");
      context.read<ChatProvider>().isUserOnline(receiverId: widget.receiverId);
      context.read<ChatProvider>().leaveScreen();
    }
  }

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    cp.clearMsgLimit();

    Future.delayed(Duration.zero, () {
      if(mounted) {
        cp.listenToMessages();
      }
      if(mounted) {
        cp.joinScreen();
      }
      if(mounted) {
        cp.isUserTyping();
      }
      if(mounted) {
        cp.isScreenOn(receiverId: widget.receiverId);
      }
      if(mounted) {
        cp.isUserOnline(receiverId: widget.receiverId);
      }
      if(mounted) {
        cp.seeMsg(
          receiverId: widget.receiverId, 
          isGroup: widget.isGroup
        );
      }
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

        cp = context.read<ChatProvider>();

        return WillPopScope(
          onWillPop: () async {
            await cp.leaveScreen();
            cp.clearSelectedMessages();
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
                                    ));
                                  }
                                },
                                child: TopBarChat(
                                  avatar: context.watch<ChatProvider>().isSelectedMessages ? "" : widget.avatar,
                                  barTitle: context.watch<ChatProvider>().isSelectedMessages ? "" : widget.title,
                                  subTitle: context.watch<ChatProvider>().isSelectedMessages ? "" : widget.isGroup 
                                  ? context.watch<ChatProvider>().isTyping != "" 
                                  ? context.read<ChatProvider>().isTyping 
                                  : widget.subtitle 
                                  : context.watch<ChatProvider>().isTyping != "" 
                                  ? context.read<ChatProvider>().isTyping
                                  : context.watch<ChatProvider>().isOnline ?? "",
                                  primaryAction: context.watch<ChatProvider>().isSelectedMessages  
                                  ? PopupMenuButton(
                                      color: ColorResources.white,
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: ColorResources.white,
                                      ),
                                      itemBuilder: (context) => [
                                        if(widget.isGroup)
                                          PopupMenuItem(
                                            child: Text("Info",
                                              style: dongleLight.copyWith(
                                                fontSize: Dimensions.fontSizeSmall,
                                                color: ColorResources.textBlackPrimary
                                              ),
                                            ),
                                            value: "info-msg",
                                          ),
                                        PopupMenuItem(
                                          child: Text("Hapus Pesan Untuk Saya",
                                            style: dongleLight.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: ColorResources.textBlackPrimary
                                            ),
                                          ),
                                          value: "delete-msg-bulk-soft",
                                        ),
                                        PopupMenuItem(
                                          child: Text("Hapus Untuk Semua Orang",
                                            style: dongleLight.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
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
                                              List<Readers> readers = context.watch<ChatProvider>().whoReads.isEmpty
                                              ? [] 
                                              : context.read<ChatProvider>().whoReads;
                                              if(readers.isEmpty) {
                                                return SizedBox(
                                                  height: 80.0,
                                                  child: Center(
                                                    child: Text("No Views",
                                                      style: dongleLight.copyWith(
                                                        color: ColorResources.black,
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
                                                            color: ColorResources.black,
                                                          ),
                                                        ),
                                                        title: Text(readers[i].name,
                                                          style: dongleLight.copyWith(
                                                            fontSize: Dimensions.fontSizeSmall,
                                                            color: ColorResources.textBlackPrimary
                                                          ),
                                                        ),
                                                        subtitle: Container(
                                                          margin: const EdgeInsets.only(top: 8.0),
                                                          child: Text(DateFormat.Hm().format(readers[i].seen),
                                                            style: dongleLight.copyWith(
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
                                    onPressed: () async {
                                      await context.read<ChatProvider>().deleteChat(context, receiverId: widget.receiverId);
                                      Navigator.of(context).pop();
                                    },
                                  ),  
                                  secondaryAction: context.watch<ChatProvider>().selectedMessages.isNotEmpty 
                                  ? IconButton(
                                    onPressed: () {
                                      context.read<ChatProvider>().clearSelectedMessages();
                                    }, 
                                    icon: const Icon(
                                      Icons.close,
                                      color: ColorResources.white  
                                    )
                                  )
                                  : IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: ColorResources.white
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, Widget? child) {
        if(chatProvider.messageStatus == MessageStatus.loading) {
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
        if(chatProvider.messages!.isNotEmpty) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
              child: NotificationListener(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollEndNotification) {
                    if (notification.metrics.pixels == notification.metrics.maxScrollExtent) {
                      chatProvider.fetchMessages(10);
                    }
                  } 
                  return false;
                },
                child: GroupedListView<ChatMessage, dynamic>(
                    physics: const ScrollPhysics(),
                    controller: context.read<ChatProvider>().scrollController,
                    elements: chatProvider.messages!,
                    groupBy: (el) => DateFormat('dd MMM yyyy').format(el.sentTime),
                    groupSeparatorBuilder:(date) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0)
                            ),
                            child: Text(date,
                              style: dongleLight.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                fontWeight: FontWeight.bold,
                                color: ColorResources.grey
                              )
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    },
                    order: GroupedListOrder.ASC,
                    groupComparator: (el1, el2) => el2.compareTo(el1),
                    itemComparator: (el1, el2) => el2.sentTime.compareTo(el1.sentTime),
                    shrinkWrap: true,
                    reverse: true,
                    indexedItemBuilder: (BuildContext context, ChatMessage message, int i) {
                      if(i == 0 && context.watch<ChatProvider>().fetchMessageStatus == FetchMessageStatus.loading) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(
                            child: SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                color: ColorResources.loaderBluePrimary,
                              ),
                            ),
                          ),
                        );
                      }
                      bool isOwnMessage = context.read<AuthenticationProvider>().userId() == message.senderId;
                      return CustomChatListViewTile(
                        deviceWidth: deviceWidth * 0.80, 
                        deviceHeight: deviceHeight, 
                        isGroup: widget.isGroup,
                        isOwnMessage: isOwnMessage, 
                        message: message, 
                      );                
                    },
                  ),
              )
            ),
          );
        } else {
          return Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text("Be the first to say Hi!",
                style: dongleLight.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: ColorResources.textBlackPrimary
                ),
              ),
            ),
          );
        }
      },
    );  
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
        fillColor: ColorResources.transparent,
        label: Container(),
        controller: context.read<ChatProvider>().messageTextEditingController,
        focusNode: context.read<ChatProvider>().messageFocusNode,
        onSaved: (val) {},
        onChange: (val) async {
          context.read<ChatProvider>().onChangeMsg(context, val);
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
        color: ColorResources.white,
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

