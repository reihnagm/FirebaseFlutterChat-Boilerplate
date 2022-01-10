// import 'package:chatv28/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/basewidget/message_bubble.dart';
import 'package:chatv28/models/chat_message.dart';
import 'package:chatv28/basewidget/rounded_image.dart';
import 'package:ionicons/ionicons.dart';

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

class CustomListViewUsersTile extends StatelessWidget {
  final double height;
  final bool group;
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final Function onTap;
  final Function? onLongPress;

  const CustomListViewUsersTile({
    Key? key, 
    required this.height,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
      : readCount == 0 
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
              color: ColorResources.loaderBluePrimary,
              size: height * 0.10,
            )
          ],
        ) 
      : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.50,
            child: Text(subtitle, 
            softWrap: true,
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: ColorResources.textBlackPrimary,
                fontSize: Dimensions.fontSizeExtraSmall,
              )
            ),
          ),
          const SizedBox(width: 30.0),
          subtitle.isNotEmpty ?
          isRead
          ? const Icon(
              Ionicons.checkmark_done,
              size: 16.0,
              color: Colors.green,  
            )  
          : const Icon(
              Ionicons.checkmark_done,
              size: 16.0,
              color: Colors.black,  
            )
          : const SizedBox()
        ],
      )     
    );
  }

}

class CustomListViewTileWithoutActivity extends StatelessWidget {
  final double height;
  final bool group;
  final String title;
  final String subtitle;
  final String contentGroup;
  final String imagePath;
  final bool isActivity;
  final Function onTap;
  final bool isRead;
  final bool isOwnMessage;
  final int readCount;

  const CustomListViewTileWithoutActivity({
    Key? key, 
    required this.height,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.contentGroup,
    required this.imagePath,
    required this.isActivity,
    required this.onTap,
    required this.isRead,
    required this.isOwnMessage,
    required this.readCount,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      leading: RoundedImageNetworkWithoutStatusIndicator(
        key: UniqueKey(),
        imagePath: imagePath, 
        size: height / 2, 
        group: group
      ),
      title: Text(title,
        style: TextStyle(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          fontWeight: FontWeight.bold
        )
      ),
      trailing: isRead
      ? const SizedBox()
      : readCount == 0 
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
              color: ColorResources.loaderBluePrimary,
              size: height * 0.10,
            )
          ],
        ) 
      : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(group)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.50,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(subtitle, 
                    softWrap: true,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.bold,
                      color: ColorResources.textBlackPrimary,
                      fontSize: Dimensions.fontSizeExtraSmall,
                    )
                  ),
                  const SizedBox(width: 5.0),
                  if(subtitle.isNotEmpty)
                    Text(":",
                      style: TextStyle(
                        color: ColorResources.textBlackPrimary,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  const SizedBox(width: 5.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.30,
                    child: Text(contentGroup, 
                      softWrap: true,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        color: ColorResources.textBlackPrimary,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      )
                    ),
                  ),
                ],
              ) 
            ),
          if(!group)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.50,
              child: Row(
                children: [
                  subtitle.isNotEmpty ?
                  isOwnMessage ?
                    isRead
                    ? const Icon(
                        Ionicons.checkmark_done,
                        size: 16.0,
                        color: Colors.green,  
                      )  
                    : const Icon(
                        Ionicons.checkmark_done,
                        size: 16.0,
                        color: Colors.black,  
                      )
                  : const SizedBox()
                  : const SizedBox(),
                  isOwnMessage 
                  ? const SizedBox(width: 5.0)
                  : const SizedBox(),
                  Text(subtitle, 
                    softWrap: true,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: ColorResources.textBlackPrimary,
                      fontSize: Dimensions.fontSizeExtraSmall,
                    )
                  ),
                ],
              )
            ),
        ],
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
  final String chatUid;

  const CustomChatListViewTile({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.isGroup,
    required this.isOwnMessage,
    required this.message,
    required this.chatUid,
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
            chatUid: chatUid
          )
        : ImageMessageBubble(
            isOwnMessage: isOwnMessage, 
            message: message, 
            height: 150.0, 
            width: 150.0
          )
      ],
    );
  }
}