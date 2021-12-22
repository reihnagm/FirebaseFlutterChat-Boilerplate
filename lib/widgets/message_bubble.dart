import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:chatv28/models/chat_message.dart';

class TextMessageBubble extends StatelessWidget {

  final bool isOwnMessage;
  final ChatMessage message;
  final double height;
  final double width;

  const TextMessageBubble({
    Key? key, 
    required this.isOwnMessage,
    required this.message,
    required this.width,
    required this.height
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
    
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: colorScheme
      ), 
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message.content, 
            style: TextStyle(
              fontSize: 14.0,
              color: isOwnMessage 
              ? Colors.black
              : Colors.white
            )
          ),
          const SizedBox(height: 5.0),
          Text(timeago.format(message.sentTime), 
            style: TextStyle(
              fontSize: 11.0,
              color: isOwnMessage 
              ? Colors.black
              : Colors.white
            )
          ),
        ],
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
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.02,
        vertical: height * 0.03
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(timeago.format(message.sentTime), 
              style: TextStyle(
                fontSize: 11.0,
                color: isOwnMessage ? Colors.black : Colors.white
              )
            ),
          )
        ],
      ),
    );
  }
}