// import 'package:chat/widgets/message_bubble.dart';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';

import 'package:chat/utils/custom_themes.dart';
import 'package:chat/utils/box_shadow.dart';
import 'package:chat/utils/color_resources.dart';
import 'package:chat/utils/dimensions.dart';
import 'package:chat/basewidgets/message_bubble.dart';
import 'package:chat/models/chat_message.dart';
import 'package:chat/basewidgets/rounded_image.dart';
import 'package:chat/providers/chat.dart';

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
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        isActive: isActive,
        group: group,
        key: UniqueKey(),
        size: height / 2,
      ),
      title: Text(title,
        style: dongleLight.copyWith(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          height: 0.0
        ),
      ),
      subtitle: Text(subtitle,
        style: dongleLight.copyWith(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeExtraSmall,
        ),
      ),
    );
  }
}

class CustomListViewCreateAGroupTile extends StatelessWidget {
  final double height;
  final bool group;
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isSelected;
  final Function onTap;
  final Function? onLongPress;

  const CustomListViewCreateAGroupTile({
    Key? key, 
    required this.height,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.imagePath,
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
      leading: RoundedImageNetworkWithoutStatusIndicator(
        imagePath: imagePath,
        group: group,
        key: UniqueKey(),
        size: height / 2,
      ),
      title: Text(title,
        style: dongleLight.copyWith(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          height: 0.0
        ),
      ),
      subtitle: Text(subtitle,
        style: dongleLight.copyWith(
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
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        isActive: isActive,
        group: group,
        key: UniqueKey(),
        size: height / 2,
      ),
      title: Text(title,
        style: dongleLight.copyWith(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeSmall,
          height: 0.0
        ),
      ),
      subtitle: Text(subtitle,
        style: dongleLight.copyWith(
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
  final String messageType;
  final String contentGroup;
  final String imagePath;
  final bool isActivity;
  final String receiverName;
  final Function onTap;
  final Function onLongPress;
  final bool isRead;
  final bool isOwnMessage;
  final int readCount;

  const CustomListViewTileWithoutActivity({
    Key? key, 
    required this.height,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.messageType,
    required this.contentGroup,
    required this.imagePath,
    required this.receiverName,
    required this.isActivity,
    required this.onTap,
    required this.onLongPress,
    required this.isRead,
    required this.isOwnMessage,
    required this.readCount,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTap(),
      onLongPress: () => onLongPress(),
      leading: RoundedImageNetworkWithoutStatusIndicator(
        key: UniqueKey(),
        imagePath: imagePath, 
        size: height / 2, 
        group: group
      ),
      title: Text(title,
        style: dongleLight.copyWith(
          color: ColorResources.textBlackPrimary,
          fontSize: Dimensions.fontSizeDefault,
          height: 0.0
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
          style: dongleLight.copyWith(
            color: ColorResources.white,
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
            group 
            ? Text("$receiverName sedang menulis pesan...", 
                style: dongleLight.copyWith(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[400],
                  height: 0.0,
                  fontSize: Dimensions.fontSizeSmall,
                )
              )
            : Text("Mengetik...", 
                style: dongleLight.copyWith(
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[400],
                  height: 0.0,
                  fontSize: Dimensions.fontSizeSmall,
                )
              ),
            ],
          ) 
      : Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(group)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.50,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(subtitle.isNotEmpty)
                    Text(isOwnMessage ? "You" : subtitle, 
                      style: dongleLight.copyWith(
                        color: ColorResources.textBlackPrimary,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      )
                    ),
                  const SizedBox(width: 5.0),
                  if(subtitle.isNotEmpty)
                    Text(":",
                      style: dongleLight.copyWith(
                        color: ColorResources.textBlackPrimary,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  const SizedBox(width: 5.0),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.20,
                    child: messageType == "IMAGE" 
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(contentGroup, 
                            style: dongleLight.copyWith(
                              overflow: TextOverflow.ellipsis,
                              color: ColorResources.textBlackPrimary,
                              fontSize: Dimensions.fontSizeExtraSmall,
                              height: 0.0
                            )
                          ),
                          const SizedBox(width: 5.0),
                          const Icon(
                            Icons.image, 
                            size: 16.0
                          )
                        ],
                      )
                    : Text(contentGroup, 
                        style: dongleLight.copyWith(
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
                          color: ColorResources.black,  
                        )
                    : const SizedBox()
                    : const SizedBox(),
                    isOwnMessage 
                    ? const SizedBox(width: 5.0)
                    : const SizedBox(),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.40),
                      child: messageType == "IMAGE" 
                      ? Row(
                          children: [
                            Text(subtitle, 
                              style: dongleLight.copyWith(
                                overflow: TextOverflow.ellipsis,
                                color: ColorResources.textBlackPrimary,
                                fontSize: Dimensions.fontSizeExtraSmall,
                              )
                            ),
                            const SizedBox(width: 5.0),
                            const Icon(
                              Icons.image, 
                              size: 12.0
                            )
                          ],
                        )
                      : Text(subtitle, 
                        style: dongleLight.copyWith(
                          overflow: TextOverflow.ellipsis,
                          color: ColorResources.textBlackPrimary,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        )
                      ),
                    ),
                  ],
                ),
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
    return message.softDelete && isOwnMessage 
    ? Container() 
    : Material(
      color: ColorResources.transparent,
      child: InkWell(
        onTap: () {
          if(isGroup) {
            if(isOwnMessage) {
              if(context.read<ChatProvider>().selectedMessages.isNotEmpty) {
                if(context.read<ChatProvider>().selectedMessages.isEmpty && context.read<ChatProvider>().selectedMessages.length != 2) {
                  context.read<ChatProvider>().onSelectedMessages(message);
                } else {
                  context.read<ChatProvider>().onSelectedMessagesRemove(message);
                }
              }
            }
          } else {
            if(isOwnMessage) {
              if(context.read<ChatProvider>().selectedMessages.isNotEmpty) {
                context.read<ChatProvider>().onSelectedMessages(message);
              } 
            }
          }
        },
        onLongPress: () {
          if(isGroup) {
            if(isOwnMessage) {
              if(context.read<ChatProvider>().selectedMessages.isEmpty && context.read<ChatProvider>().selectedMessages.length != 2) {
                context.read<ChatProvider>().onSelectedMessages(message);
              } else {
                context.read<ChatProvider>().onSelectedMessagesRemove(message);
              }
            }
          } else {
            if(isOwnMessage) {
              context.read<ChatProvider>().onSelectedMessages(message);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
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
                  height: 150.0, 
                  width: 150.0
                ),
                context.watch<ChatProvider>().selectedMessages.contains(message) 
              ? Container(
                  margin: const EdgeInsets.only(left: 10.0),
                  child: const Icon(
                    Icons.check,
                    size: 20.0,
                    color: ColorResources.primary,
                  ),
              ) 
              : Container()
            ],
          ),
        ),
      ),
    );
  }
}