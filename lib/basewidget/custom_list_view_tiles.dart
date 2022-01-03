// import 'package:chatv28/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/basewidget/message_bubble.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/basewidget/rounded_image.dart';

class CustomListViewTile extends StatelessWidget {
  final double height;
  final bool group;
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
    required this.group,
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
          color: ColorResources.backgroundBlueSecondary,
        )
      : null,
      onTap: () => onTap(),
      onLongPress: () => onLongPress!(),
      minVerticalPadding: height * 0.20,
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        isActive: isActive,
        group: group,
        key: UniqueKey(),
        size: height / 2,
      ),
      title: Text(title,
        style: TextStyle(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          fontWeight: FontWeight.bold
        ),
      ),
      subtitle: Text(subtitle,
        style: TextStyle(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeExtraSmall,
        ),
      ),
    );
  }
}

class CustomListViewTileWithActivity extends StatelessWidget {
  final double height;
  final bool group;
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final bool isActivity;
  final Function onTap;
  final bool isRead;
  final int readCount;

  const CustomListViewTileWithActivity({
    Key? key, 
    required this.height,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.isActivity,
    required this.onTap,
    required this.isRead,
    required this.readCount,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      leading: RoundedImageNetworkWithStatusIndicator(
        key: UniqueKey(),
        imagePath: imagePath, 
        size: height / 2, 
        isActive: isActive,
        group: group
      ),
      minVerticalPadding: height * 0.20,
      title: Text(title,
        style: TextStyle(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          fontWeight: FontWeight.bold
        )
      ),
      trailing: isRead
      ? const SizedBox()
      : Container(
        width: 20.0,
        height: 20.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorResources.error,
          boxShadow: boxShadow,
          shape: BoxShape.circle
        ),
        child: Text((readCount).toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: Dimensions.fontSizeExtraSmall
          ),
        ),
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
        ) 
      : Text(subtitle, 
          style: TextStyle(
            color: ColorResources.textBlackPrimary,
            fontSize: Dimensions.fontSizeExtraSmall,
          )
        )      
    );
  }

}

class CustomChatListViewTile extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final bool isGroup;
  final bool isOwnMessage;
  final ChatMessage message;

  const CustomChatListViewTile({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.isGroup,
    required this.isOwnMessage,
    required this.message,
    Key? key
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        message.type == MessageType.text 
        ? TextMessageBubble(
            isGroup: isGroup,
            isOwnMessage: isOwnMessage, 
            message: message, 
          )
        : ImageMessageBubble(
            isOwnMessage: isOwnMessage, 
            message: message, 
            height: deviceHeight * 0.30, 
            width: deviceWidth * 0.55
          )
      ],
    );
  }
}