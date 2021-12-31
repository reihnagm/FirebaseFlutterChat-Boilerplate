import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:chatv28/utils/box_shadow.dart';
import 'package:chatv28/utils/color_resources.dart';
import 'package:chatv28/basewidget/animated_dialog/show_animate_dialog.dart';
import 'package:chatv28/basewidget/signout_confirmation_dialog/signout_confirmation_dialog.dart';
import 'package:chatv28/models/chat.dart';
import 'package:chatv28/pages/chat.dart';
import 'package:chatv28/services/database.dart';
import 'package:chatv28/services/navigation.dart';
import 'package:chatv28/basewidget/button/custom_button.dart';
import 'package:chatv28/models/chat_user.dart';
import 'package:chatv28/providers/authentication.dart';
import 'package:chatv28/providers/user.dart';
import 'package:chatv28/basewidget/custom_input_fields.dart';
import 'package:chatv28/basewidget/custom_list_view_tiles.dart';
import 'package:chatv28/basewidget/top_bar.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({ Key? key }) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late double deviceHeight; 
  late double deviceWidth;

  late DatabaseService databaseService;
  late TextEditingController searchFieldTextEditingController = TextEditingController();

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      Provider.of<UserProvider>(context, listen: false).getUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    databaseService = DatabaseService();
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return buildUI();
  }

  Widget buildUI() {
    return Builder(
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.03,
            vertical: deviceHeight * 0.02
          ),
          height: deviceHeight * 0.98,
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TopBar("Users",
                barTitleColor: ColorResources.backgroundBlackPrimary,
                primaryAction: IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: ColorResources.backgroundBlackPrimary,
                  ),
                  onPressed: () async {
                    showAnimatedDialog(context,
                      const SignOutConfirmationDialog(),
                      isFlip: false
                    );
                  }, 
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  boxShadow: boxShadow
                ),
                child: CustomTextSearchField(
                  onEditingComplete: (val) {
                    context.read<UserProvider>().getUsers(name: val);
                    FocusScope.of(context).unfocus();
                  },
                  controller: searchFieldTextEditingController,
                  icon: Icons.search,
                  hintText: "Search", 
                ),
              ),
              Consumer<AuthenticationProvider>(
                builder: (BuildContext context, AuthenticationProvider authenticationProvider, Widget? child) {
                  if(authenticationProvider.chatUser == null) {
                    return Container();
                  }
                  return usersList();
                },
              ),
              createChatButton()
            ],
          ),
        );
      },
    );
  }

  Widget usersList() {
    List<ChatUser>? _users = context.read<UserProvider>().users;
    return Expanded(child: () {
      if(_users != null) {
        if(_users.isNotEmpty) {
          List<ChatUser> users = _users.where((el) => el.uid != context.read<AuthenticationProvider>().chatUser!.uid).toList();
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (BuildContext context, int i) {
              return CustomListViewTile(
                title: users[i].name!,
                subtitle: "Last Active: ${timeago.format(users[i].lastActive!)}",
                height: deviceHeight * 0.10,  
                imagePath: users[i].imageUrl!, 
                isActive: users[i].isUserOnline(), 
                isSelected: context.watch<UserProvider>().selectedUsers.contains(users[i]), 
                onTap: () async {
                  QuerySnapshot<Map<String, dynamic>> checkCreateChat = (await databaseService.checkCreateChat(users[i].uid!))!;
                  if(checkCreateChat.docs.isEmpty) {
                    DocumentReference? doc = await databaseService.createChat(
                      {
                        "is_group": false,
                        "is_activity": false,
                        "on_screens": FieldValue.arrayUnion([ 
                          {
                            "userUid": context.read<AuthenticationProvider>().chatUser!.uid,
                            "token": context.read<AuthenticationProvider>().chatUser!.token,
                            "on": true
                          }
                        ]),
                        "relations": [
                          context.read<AuthenticationProvider>().chatUser!.uid,
                          users[i].uid
                        ],
                        "readers": [],
                        "members": [
                          {
                            "uid": context.read<AuthenticationProvider>().chatUser!.uid,
                            "email": context.read<AuthenticationProvider>().chatUser!.email,
                            "image": context.read<AuthenticationProvider>().chatUser!.imageUrl,
                            "isOnline": context.read<AuthenticationProvider>().chatUser!.isOnline,
                            "last_active": context.read<AuthenticationProvider>().chatUser!.lastActive,
                            "name": context.read<AuthenticationProvider>().chatUser!.name,
                            "token": context.read<AuthenticationProvider>().chatUser!.token
                          },
                          {
                            "uid": users[i].uid,
                            "email":users[i].email,
                            "image": users[i].imageUrl,
                            "isOnline": users[i].isOnline,
                            "last_active": users[i].lastActive,
                            "name": users[i].name,
                            "token": context.read<AuthenticationProvider>().chatUser!.token
                          }
                        ], 
                      });
                      NavigationService.pushNav(context, ChatPage(
                        chat: Chat(
                          uid: doc!.id, 
                          currentUserId: context.read<AuthenticationProvider>().chatUser!.uid!, 
                          activity: false, 
                          group: false, 
                          members: [
                            ChatUser(
                              uid: context.read<AuthenticationProvider>().chatUser!.uid, 
                              name: context.read<AuthenticationProvider>().chatUser!.name, 
                              email: context.read<AuthenticationProvider>().chatUser!.name, 
                              imageUrl: context.read<AuthenticationProvider>().chatUser!.imageUrl, 
                              isOnline: context.read<AuthenticationProvider>().chatUser!.isOnline, 
                              lastActive: context.read<AuthenticationProvider>().chatUser!.lastActive,
                              token: users[i].token
                            ),
                            ChatUser(
                              uid: users[i].uid, 
                              name: users[i].name, 
                              email: users[i].email, 
                              imageUrl: users[i].imageUrl, 
                              isOnline: users[i].isOnline, 
                              lastActive: users[i].lastActive,
                              token: users[i].token
                            ),
                          ], 
                          readers: [],
                          messages: []
                        )
                      ));
                  } else {
                    NavigationService.pushNav(context, ChatPage(
                      chat: Chat(
                        uid: checkCreateChat.docs[0].id, 
                        currentUserId: context.read<AuthenticationProvider>().chatUser!.uid!, 
                        activity: false, 
                        group: false, 
                        members: [
                          ChatUser(
                            uid: context.read<AuthenticationProvider>().chatUser!.uid, 
                            name: context.read<AuthenticationProvider>().chatUser!.name, 
                            email: context.read<AuthenticationProvider>().chatUser!.name, 
                            imageUrl: context.read<AuthenticationProvider>().chatUser!.imageUrl, 
                            isOnline: context.read<AuthenticationProvider>().chatUser!.isOnline, 
                            lastActive: context.read<AuthenticationProvider>().chatUser!.lastActive,
                            token: users[i].token
                          ),
                          ChatUser(
                            uid: users[i].uid, 
                            name: users[i].name, 
                            email: users[i].email, 
                            imageUrl: users[i].imageUrl, 
                            isOnline: users[i].isOnline, 
                            lastActive: users[i].lastActive,
                            token: users[i].token
                          ),
                        ], 
                        readers: [],
                        messages: []
                      )
                    ));
                  }
                },
                onLongPress: () {
                  context.read<UserProvider>().updateSelectedUsers(users[i]);
                },
              );
            },
          );
        } else {
          return const Center(
            child: Text("No Users Found.",
              style: TextStyle(
                color: ColorResources.textBlackPrimary
              ),
            ),
          );
        }
      } else {
        return const Center(
          child: SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(
              color: ColorResources.loaderBluePrimary,
            ),
          ),
        );
      }
    }());
  }

  Widget createChatButton() {
    return Visibility(
      visible:  context.watch<UserProvider>().selectedUsers.isNotEmpty,
      child: CustomButton(
        onTap: () {
           context.read<UserProvider>().createChat(context);
        }, 
        isBoxShadow: false,
        btnTxt: context.read<UserProvider>().selectedUsers.length == 1 
        ? "Chat with ${context.read<UserProvider>().selectedUsers.first.name}"
        : "Create Group Chat"
      )
    );
  }
}