import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import 'package:chatv28/basewidget/full_photo.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/models/chat_message.dart';

class TextMessageBubble extends StatefulWidget {
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
  State<TextMessageBubble> createState() => _TextMessageBubbleState();
}

class _TextMessageBubbleState extends State<TextMessageBubble> {

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

    Color colorScheme = widget.isOwnMessage 
    ? Colors.lightGreen[100]!
    : const Color.fromRGBO(51, 49, 68, 1.0);

    BorderRadiusGeometry borderRadius = widget.isOwnMessage 
    ? const BorderRadius.only(
        topLeft: Radius.circular(15),
        bottomRight: Radius.circular(15), 
        bottomLeft: Radius.circular(15), 
      )
    : const BorderRadius.only(
        topRight: Radius.circular(15),
        bottomRight: Radius.circular(15), 
        bottomLeft: Radius.circular(15), 
      );

    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical:  10.0
      ),
      decoration: BoxDecoration(
        color: colorScheme,
        borderRadius: borderRadius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.isGroup 
          ? Column( 
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.isOwnMessage 
                ? const SizedBox() 
                : Text(
                  widget.message.senderName,
                  style: TextStyle(
                    color: widget.isOwnMessage 
                    ? ColorResources.textBlackPrimary 
                    : ColorResources.white,
                    fontSize: Dimensions.fontSizeExtraSmall
                  ),
                ),
                const SizedBox(height: 6.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 130),
                    child: Text(widget.message.content,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: widget.isOwnMessage 
                        ? ColorResources.black  
                        : ColorResources.white,
                        height: 1.5,
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
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
                ) 
              ],
            ) 
          :  Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 130),
                      child: Text(widget.message.content,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: widget.isOwnMessage 
                          ? ColorResources.black  
                          : ColorResources.white,
                          height: 1.5,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                  ],
                ),
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
            const SizedBox(height: 6.0),
            Text(DateFormat("HH:mm").format(widget.message.sentTime),
              style: TextStyle(
                color: widget.isOwnMessage 
                ? Colors.black
                : Colors.white,
                fontSize: Dimensions.fontSizeOverExtraSmall,
              ),
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
    ? Colors.lightGreen[100]!
    : const Color.fromRGBO(51, 49, 68, 1.0);
    return message.content == "loading" ? 
      Container(
        width: width,
        height: 180.0,
        margin: const EdgeInsets.only(top: 15.0),
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 10.0
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
      ) : Container(
      width: width,
      margin: const EdgeInsets.only(top: 15.0),
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 10.0
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
            child: CachedNetworkImage(
              imageUrl: message.content,
              imageBuilder: (BuildContext context, ImageProvider<Object> imageProvider) {
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover
                    )
                  ),
                );
              },
              placeholder: (BuildContext context, String url) {
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/default-image.png'),
                      fit: BoxFit.cover
                    )
                  ),
                );
              },
              errorWidget: (BuildContext context, String url, dynamic error) {
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/default-image.png'),
                      fit: BoxFit.cover
                    )
                  ),
                );
              },
            )
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
                fontSize: Dimensions.fontSizeOverExtraSmall,
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
  }
}