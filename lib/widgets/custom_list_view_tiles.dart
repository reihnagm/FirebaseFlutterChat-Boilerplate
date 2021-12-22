// import 'package:chatv28/widgets/message_bubble.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/widgets/rounded_image.dart';

class CustomListViewTile extends StatelessWidget {
  final double height;
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final bool isSelected;
  final Function onTap;
  final Function? onLongPress;

  const CustomListViewTile({
    Key? key, 
    required this.height,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: isSelected 
      ? const Icon(
          Icons.check,
          color: Colors.white,
        )
      : null,
      onTap: () => onTap(),
      onLongPress: () => onLongPress!(),
      minVerticalPadding: height * 0.20,
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        isActive: isActive,
        key: UniqueKey(),
        size: height / 2,
      ),
      title: Text(title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.w500
        ),
      ),
      subtitle: Text(subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12.0,
          fontWeight: FontWeight.w500
        ),
      ),
    );
  }
}

class CustomListViewTileWithActivity extends StatelessWidget {
  final double height;
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final bool isActivity;
  final Function onTap;

  const CustomListViewTileWithActivity({
    Key? key, 
    required this.height,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.isActivity,
    required this.onTap
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      leading: RoundedImageNetworkWithStatusIndicator(
        key: UniqueKey(),
        imagePath: imagePath, 
        size: height / 2, 
        isActive: isActive
      ),
      minVerticalPadding: height * 0.20,
      title: Text(title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.w500
        )
      ),
      subtitle: isActivity 
      ? Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SpinKitThreeBounce(
            color: Colors.white54,
            size: height * 0.10,
          )
        ],
      ) : Text(subtitle, 
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12.0,
          fontWeight: FontWeight.w400
        )
      )
    );
  }

}

class CustomChatListViewTile extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final bool isOwnMessage;
  final ChatMessage message;
  final ChatUser sender;

  const CustomChatListViewTile({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.isOwnMessage,
    required this.message,
    required this.sender,
    Key? key
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    Color colorScheme = isOwnMessage 
    ? const Color.fromRGBO(250, 250, 250, 1.0) 
    : const Color.fromRGBO(51, 49, 68, 1.0);
    return Row(
      mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Hello",
                  textAlign: TextAlign.justify,
                  style:  TextStyle(
                    color: isOwnMessage 
                    ? Colors.black 
                    : Colors.white,
                    fontSize: 14.0,
                    height: 1.8
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(timeago.format(message.sentTime),
                  style: TextStyle(
                    color: isOwnMessage 
                    ? Colors.black 
                    : Colors.white,
                    fontSize: 11.0,
                  ),
                ),
              ],
            )
          ),
        ),
        // !isOwnMessage 
        // ? RoundedImageNetwork(
        //     key: UniqueKey(),
        //     imagePath: sender.imageUrl!, 
        //     size: deviceWidth * 0.08
        //   ) 
        // : Container(),
        // message.type == MessageType.text 
        // ? TextMessageBubble(
        //   isOwnMessage: isOwnMessage, 
        //   message: message, 
        //   width: deviceWidth,
        //   height: deviceHeight * 0.06
        // )
        // : ImageMessageBubble(
        //   isOwnMessage: isOwnMessage, 
        //   message: message, 
        //   height: deviceHeight * 0.30, 
        //   width: deviceWidth * 0.55
        // )
      ],
    );
  }
}