import 'package:chatv28/basewidget/full_photo.dart';
import 'package:chatv28/providers/chat.dart';
import 'package:chatv28/providers/chats.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:provider/provider.dart';

class TextMessageBubble extends StatefulWidget {
  final bool isGroup;
  final bool isOwnMessage;
  final ChatMessage message;
  final String chatUid;

  const TextMessageBubble({
    Key? key, 
    required this.isGroup,
    required this.isOwnMessage,
    required this.message,
    required this.chatUid
  }) : super(key: key);

  @override
  State<TextMessageBubble> createState() => _TextMessageBubbleState();
}

class _TextMessageBubbleState extends State<TextMessageBubble> {
  late ChatsProvider chatsProvider;


  @override
  Widget build(BuildContext context) {
    chatsProvider = context.read<ChatsProvider>();
    // List<Color> colorScheme = isOwnMessage 
    // ? [
    //     const Color.fromRGBO(0, 136, 249, 1.0),
    //     const Color.fromRGBO(0, 82, 218, 1.0)
    //   ] 
    // : [
    //   const Color.fromRGBO(51, 49, 68, 1.0),
    //   const Color.fromRGBO(51, 49, 68, 1.0)
    // ];
    Color colorScheme = widget.isOwnMessage 
    ? const Color.fromRGBO(250, 250, 250, 1.0)
    : const Color.fromRGBO(51, 49, 68, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical:  10.0
      ),
      decoration: BoxDecoration(
        color: colorScheme,
        borderRadius: BorderRadius.circular(15.0)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.isGroup 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isOwnMessage ? "You" : widget.message.senderName,
                  style: TextStyle(
                    color: widget.isOwnMessage ? ColorResources.textBlackPrimary : ColorResources.white,
                    fontSize: Dimensions.fontSizeExtraSmall
                  ),
                ),
                // const SizedBox(width: 80.0),
                widget.isOwnMessage ? PopupMenuButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorResources.black,
                    size: 16.0,
                  ),
                  itemBuilder: (BuildContext context) { 
                    return <PopupMenuItem<String>>[
                      PopupMenuItem<String>(
                        child: Text('Info',
                          style: TextStyle(
                            fontSize: Dimensions.fontSizeExtraSmall
                          ),
                        ),
                        value: 'info'
                      ),
                      const PopupMenuItem(
                        child: Icon(
                          Icons.delete,
                          color: ColorResources.error,
                          size: 16.0,
                        ),
                        value: 'delete'
                      ),
                    ];
                  },
                onSelected: (String value) {
                  if(value == "info") {
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
                        List<Readers> readers = widget.message.readers.where((el) => el.isRead == true).toList();
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
                }) : const SizedBox(),
              ],
            ) : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.message.senderName,
                  style: TextStyle(
                    color: widget.isOwnMessage ? ColorResources.textBlackPrimary : ColorResources.white,
                    fontSize: Dimensions.fontSizeExtraSmall
                  ),
                ),
                widget.isOwnMessage ? PopupMenuButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorResources.black,
                    size: 16.0,
                  ),
                  itemBuilder: (BuildContext context) { 
                    return <PopupMenuItem<String>>[
                      const PopupMenuItem(
                        child: Icon(
                          Icons.delete,
                          color: ColorResources.error,
                          size: 16.0,
                        ),
                        value: 'delete'
                      ),
                    ];
                  },
                onSelected: (String value) async {
                  if(value == "delete") {
                    await chatsProvider.deleteMsg(chatId: widget.chatUid, msgId: widget.message.uid);
                  }
                }) : const SizedBox(),
              ],
            ),
          Text(widget.message.content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: widget.isOwnMessage 
              ? Colors.black  
              : Colors.white,
              fontSize: Dimensions.fontSizeExtraSmall,
              height: 1.8
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat("HH:mm").format(widget.message.sentTime),
                style: TextStyle(
                  color: widget.isOwnMessage 
                  ? Colors.black
                  : Colors.white,
                  fontSize: Dimensions.fontSizeExtraSmall,
                ),
              ),
              const SizedBox(width: 10.0),
              if(widget.isOwnMessage)
                widget.message.isRead
                ? const Icon(
                    Ionicons.checkmark_done,
                    size: 16.0,
                    color: Colors.green,  
                  )  
                : Icon(
                    Ionicons.checkmark_done,
                    size: 16.0,
                    color: widget.isOwnMessage 
                    ? Colors.black 
                    : Colors.white  
                  ),
            ],
          ), 
        ],
      )
    );
  }
}

class ImageMessageBubble extends StatelessWidget {
  final bool isOwnMessage; 
  final ChatMessage message;
  final double height;
  final double width;

  const ImageMessageBubble({Key? key, 
    required this.isOwnMessage,
    required this.message,
    required this.height,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List<Color> colorScheme = isOwnMessage 
    // ? [
    //     const Color.fromRGBO(0, 136, 249, 1.0),
    //     const Color.fromRGBO(0, 82, 218, 1.0)
    //   ] 
    // : [
    //   const Color.fromRGBO(0, 136, 249, 1.0),
    //   const Color.fromRGBO(0, 82, 218, 1.0)
    // ];
    Color colorScheme = isOwnMessage 
    ? const Color.fromRGBO(250, 250, 250, 1.0) 
    : const Color.fromRGBO(51, 49, 68, 1.0);
    DecorationImage decorationImage = DecorationImage(
      image: NetworkImage(message.content),
      fit: BoxFit.cover
    ); 
    return Consumer<ChatProvider>(
      builder: (BuildContext context, ChatProvider chatProvider, Widget? child) {
        if(message.content == "loading") {
          return Container(
            width: width,
            height: 180.0,
            margin: const EdgeInsets.only(top: 15.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical:  10.0
            ),
            decoration: BoxDecoration(
              color: colorScheme,
              borderRadius: BorderRadius.circular(15.0),
            ), 
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(
                    color: ColorResources.loaderBluePrimary,
                  )
                )
              ],
            ),
          );
        }
        return Container(
          width: width,
          margin: const EdgeInsets.only(top: 15.0),
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical:  10.0
          ),
          decoration: BoxDecoration(
            color: colorScheme,
            borderRadius: BorderRadius.circular(15.0),
          ), 
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  NavigationService().pushNav(context, FullPhotoScreen(url: message.content));
                },
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: decorationImage 
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat("HH:mm").format(message.sentTime),
                    style: TextStyle(
                      color: isOwnMessage 
                      ? Colors.black 
                      : Colors.white,
                      fontSize: Dimensions.fontSizeExtraSmall,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  if(isOwnMessage)
                    message.isRead
                    ? const Icon(
                        Ionicons.checkmark_done,
                        size: 20.0,
                        color: Colors.green  
                      )  
                    : const Icon(
                        Ionicons.checkmark_done,
                        size: 20.0,
                        color: Colors.black,  
                      ),
                ],
              ),
            ],
          ),
        );
      },
    ); 
  }
}