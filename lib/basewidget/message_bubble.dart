import 'package:chatv28/basewidget/animated_dialog/show_animate_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:popover/popover.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';

class TextMessageBubble extends StatelessWidget {
  final bool isGroup;
  final bool isOwnMessage;
  final ChatMessage message;

  const TextMessageBubble({
    Key? key, 
    required this.isGroup,
    required this.isOwnMessage,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List<Color> colorScheme = isOwnMessage 
    // ? [
    //     const Color.fromRGBO(0, 136, 249, 1.0),
    //     const Color.fromRGBO(0, 82, 218, 1.0)
    //   ] 
    // : [
    //   const Color.fromRGBO(51, 49, 68, 1.0),
    //   const Color.fromRGBO(51, 49, 68, 1.0)
    // ];
    Color colorScheme = isOwnMessage 
    ? const Color.fromRGBO(250, 250, 250, 1.0) 
    : const Color.fromRGBO(51, 49, 68, 1.0);
    
    return  ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 60,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 15.0),
        padding:  EdgeInsets.symmetric(
          horizontal: isGroup ? 10.0 : 15.0,
          vertical: isGroup ? 10.0 : 15.0
        ),
        decoration: BoxDecoration(
          color: colorScheme,
          borderRadius: BorderRadius.circular(15.0)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            isGroup 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOwnMessage ? "You" : message.senderName,
                    style: TextStyle(
                      color: isOwnMessage ? ColorResources.textBlackPrimary : ColorResources.white,
                      fontSize: Dimensions.fontSizeExtraSmall
                    ),
                  ),
                  const SizedBox(width: 30.0),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0), 
                            topRight: Radius.circular(10.0)
                          ),
                        ),
                        context: context, 
                        builder: (context) {
                          return Container(
                            margin: EdgeInsets.all(Dimensions.marginSizeDefault),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: 5,
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
                                        image: const DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage("https://i.pravatar.cc/300"),
                                        ),
                                        borderRadius: BorderRadius.circular(30.0),
                                        color: Colors.black,
                                      ),
                                    ),
                                    title: Text("Ridwan",
                                      style: TextStyle(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: ColorResources.textBlackPrimary
                                      ),
                                    ),
                                    subtitle: Container(
                                      margin: const EdgeInsets.only(top: 8.0),
                                      child: Text("10:00",
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
                    },
                    child: const Icon(
                      Icons.more_vert,
                      color: ColorResources.white,
                      size: 20.0,
                    ),
                  ),
                ],
              ) 
            : const SizedBox(),
            Text(message.content,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: isOwnMessage 
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
                Text(timeago.format(message.sentTime),
                  style: TextStyle(
                    color: isOwnMessage 
                    ? Colors.black 
                    : Colors.white,
                    fontSize:  Dimensions.fontSizeExtraSmall,
                  ),
                ),
                const SizedBox(width: 10.0),
                message.isRead
                ? const Icon(
                    Ionicons.checkmark_done,
                    size: 20.0,
                    color: Colors.green,  
                  )  
                : Icon(
                    Ionicons.checkmark_done,
                    size: 20.0,
                    color: isOwnMessage 
                    ? Colors.black 
                    : Colors.white  
                  ),
              ],
            ), 
          ],
        )
      ),
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
    return Container(
      width: width,
      margin: const EdgeInsets.only(top: 15.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0
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
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              image: decorationImage 
            ),
          ),
          const SizedBox(height: 5.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeago.format(message.sentTime),
                style: TextStyle(
                  color: isOwnMessage 
                  ? Colors.black 
                  : Colors.white,
                  fontSize: 11.0,
                ),
              ),
              const SizedBox(width: 10.0),
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
  }
}

class ListItems extends StatelessWidget {
  const ListItems({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            InkWell(
              onTap: () {
               
              },
              child: Container(
                height: 50,
                color: Colors.amber[100],
                child: const Center(child: Text('Entry A')),
              ),
            ),
            const Divider(),
            Container(
              height: 50,
              color: Colors.amber[200],
              child: const Center(child: Text('Entry B')),
            ),
            const Divider(),
            Container(
              height: 50,
              color: Colors.amber[300],
              child: const Center(child: Text('Entry C')),
            ),
          ],
        ),
      ),
    );
  }
}

List<QudsPopupMenuBase> getMenuItems() {
  return [
    QudsPopupMenuWidget(
      builder: (BuildContext context) => Container(
        width: 40.0,
        height: 40.0,
        child: Text("Info")
      )
    )
  ];
}