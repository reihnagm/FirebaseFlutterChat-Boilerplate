import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:timeago/timeago.dart' as timeago;

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
        padding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 15.0
        ),
        decoration: BoxDecoration(
          color: colorScheme,
          borderRadius: BorderRadius.circular(15.0)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isGroup 
            ? Text(
                isOwnMessage ? "You" : message.senderName,
                style: TextStyle(
                  color: isOwnMessage ? ColorResources.textBlackPrimary : ColorResources.white ,
                  fontSize: Dimensions.fontSizeExtraSmall
                ),
              ) 
            : const SizedBox(),
            isGroup 
            ? const SizedBox(height: 6.0) 
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
                    size: 17.0,
                    color: Colors.greenAccent,  
                  )  
                : Icon(
                    Ionicons.checkmark_done,
                    size: 17.0,
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
                  size: 17.0,
                  color: Colors.greenAccent,  
                )  
              : const Icon(
                  Ionicons.checkmark_done,
                  size: 17.0,
                  color: Colors.black,  
                ),
            ],
          ),
        ],
      ),
    );
  }
}