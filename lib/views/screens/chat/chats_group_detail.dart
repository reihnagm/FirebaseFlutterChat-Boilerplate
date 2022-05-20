import 'dart:io';

import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:chat/providers/authentication.dart';
import 'package:chat/utils/custom_themes.dart';
import 'package:chat/providers/chats.dart';
import 'package:chat/basewidgets/rounded_image.dart';
import 'package:chat/utils/dimensions.dart';
import 'package:chat/utils/color_resources.dart';

class ChatsGroupDetail extends StatefulWidget {
  final String title;
  final String imageUrl;
  const ChatsGroupDetail({ 
    required this.title,
    required this.imageUrl,
    Key? key 
  }) : super(key: key);

  @override
  _ChatsGroupDetailState createState() => _ChatsGroupDetailState();
}

class _ChatsGroupDetailState extends State<ChatsGroupDetail> {
  
  String imageUrl = "";
  String title = "";
  String titleMore = "";
  late ChatsProvider chatsProvider;
  late ScrollController scrollController;
  bool lastStatus = true;

  scrollListener() {
    if (isShrink != lastStatus) {
      setState(() {
        lastStatus = isShrink;
      });
    }
  }

  bool get isShrink {
    return scrollController.hasClients && scrollController.offset > (250 - kToolbarHeight);
  }

  @override
  void initState() {
    super.initState();
    chatsProvider = context.read<ChatsProvider>();
    chatsProvider.getMembersByChat();
    scrollController = ScrollController();
    scrollController.addListener(scrollListener);
    if (widget.title.length > 24) {
      titleMore = widget.title.substring(0, 24);
    } else {
      titleMore = widget.title;
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
  
    titleMore = widget.title;
    imageUrl = widget.imageUrl;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Consumer<ChatsProvider>(
              builder: (BuildContext context, ChatsProvider chatsProvider, Widget? child) {
                if(chatsProvider.memberStatus == MembersStatus.loading) {
                  return const Center(
                    child: SpinKitThreeBounce(
                      size: 20.0,
                      color: ColorResources.primary,
                    )
                  );
                }
                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverAppBar(
                      elevation: 0.0,
                      backgroundColor: ColorResources.white,
                      iconTheme: IconThemeData(
                        color: isShrink 
                        ? ColorResources.black 
                        : ColorResources.white,
                      ),
                      pinned: true,
                      expandedHeight: 250.0,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          height: 50.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50.0),
                            color: isShrink ? null : Colors.black54
                          ),
                          child: Center(
                            child: Platform.isIOS
                              ? Container(
                                margin: const EdgeInsets.only(left: 8.0),
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
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (BuildContext context, String url) => Center(
                                  child: Image.asset("assets/images/default_image.png",
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                ),
                                errorWidget: (BuildContext context, String url, dynamic error) => Center(
                                  child: Image.asset("assets/images/default_image.png",
                                    height: double.infinity,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
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
                          widget.title,
                          maxLines: 1,
                          style: dongleLight.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.bold,
                            color: ColorResources.black, 
                          ),
                        ),
                      ),
                    ),

                    if(chatsProvider.members.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text("No Members Found",
                            style: dongleLight.copyWith(
                              fontSize: Dimensions.fontSizeDefault
                            )
                          ),
                        ),
                      ),
                  

                    SliverPadding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int i) {
                            return context.read<AuthenticationProvider>().userId() == chatsProvider.members[i].uid 
                            ? Container() 
                            : ListTile(
                              onTap: () {},
                              leading: RoundedImageNetworkWithStatusIndicator(
                                key: UniqueKey(),
                                imagePath: chatsProvider.members[i].image!, 
                                size: MediaQuery.of(context).size.height * 0.10 / 2, 
                                isActive: chatsProvider.members[i].isOnline!,
                                group: false
                              ),
                              minVerticalPadding: MediaQuery.of(context).size.height * 0.10 * 0.20,
                              title: Text(chatsProvider.members[i].name!,
                                style: dongleLight.copyWith(
                                  color: ColorResources.black,
                                  fontSize: Dimensions.fontSizeSmall,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.50,
                                    child: Text("Last Active: ${timeago.format(chatsProvider.members[i].lastActive!)}", 
                                    softWrap: true,
                                      style: dongleLight.copyWith(
                                        overflow: TextOverflow.ellipsis,
                                        color: ColorResources.black,
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                      )
                                    ),
                                  ),
                                ],
                              )     
                            );
                          },
                          childCount: chatsProvider.members.length
                        ),
                      ),
                    )
                  ],
                );
              },
            );
            
            
          }, 
        )
      ),
    );
  }
}
