import 'dart:io';

import 'package:chatv28/providers/authentication.dart';
import 'package:provider/src/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:chatv28/basewidget/rounded_image.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/utils/dimensions.dart';
import 'package:chatv28/utils/color_resources.dart';

class ChatsGroupDetail extends StatefulWidget {
  final String title;
  final String imageUrl;
  final List<ChatUser> members;
  const ChatsGroupDetail({ 
    required this.title,
    required this.imageUrl,
    required this.members,
    Key? key 
  }) : super(key: key);

  @override
  _ChatsGroupDetailState createState() => _ChatsGroupDetailState();
}

class _ChatsGroupDetailState extends State<ChatsGroupDetail> {
  
  String imageUrl = "";
  String title = "";
  String titleMore = "";
  List<ChatUser> members = [];
  ScrollController? scrollController;
  bool lastStatus = true;

  scrollListener() {
    if (isShrink != lastStatus) {
      setState(() {
        lastStatus = isShrink;
      });
    }
  }

  bool get isShrink {
    return scrollController!.hasClients && scrollController!.offset > (250 - kToolbarHeight);
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController!.addListener(scrollListener);
    if (widget.title.length > 24) {
      titleMore = widget.title.substring(0, 24);
    } else {
      titleMore = widget.title;
    }
  }

  @override
  void dispose() {
    scrollController!.removeListener(scrollListener);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    
    imageUrl = widget.imageUrl;
    titleMore = widget.title;
    members = widget.members;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  iconTheme: IconThemeData(
                    color: isShrink ? Colors.black : Colors.white,
                  ),
                  pinned: true,
                  expandedHeight: 250.0,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: isShrink ? null : Colors.black54
                      ),
                      child: Center(
                        child: Platform.isIOS
                          ? Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: const Icon(Icons.arrow_back_ios)
                        )
                        : const Icon(Icons.arrow_back)
                      )
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: ClipRRect(
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (BuildContext context, String url) => const Center(
                                child: SizedBox(
                                  width: 16.0,
                                  height: 16.0,
                                  child: CircularProgressIndicator(
                                    color: ColorResources.loaderBluePrimary,
                                  )
                                )
                              ),
                              errorWidget: (BuildContext context, String url, dynamic error) => Center(
                              child: Image.network("https://pertaniansehat.com/v01/wp-content/uploads/2015/08/default-placeholder.png",
                                height: double.infinity,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: AnimatedOpacity(
                    opacity: isShrink ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      titleMore + "...",
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                  sliver: SliverList(
                   delegate: SliverChildBuilderDelegate(
                     (BuildContext context, int i) {
                       return context.read<AuthenticationProvider>().userId()== members[i].uid 
                       ? Container() 
                       : ListTile(
                        onTap: () {},
                        leading: RoundedImageNetworkWithStatusIndicator(
                          key: UniqueKey(),
                          imagePath: members[i].image!, 
                          size: MediaQuery.of(context).size.height * 0.10 / 2, 
                          isActive: members[i].isOnline!,
                          group: false
                        ),
                        minVerticalPadding: MediaQuery.of(context).size.height * 0.10 * 0.20,
                        title: Text(members[i].name!,
                          style: TextStyle(
                            color: ColorResources.textBlackPrimary,
                            fontSize: Dimensions.fontSizeSmall,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.50,
                              child: Text("Last Active: ${timeago.format(members[i].lastActive!)}", 
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
                      );
                     },
                     childCount: members.length
                   ),
                  ),
                )
              ],
            );
          }, 
        )
      ),
    );
  }
}

